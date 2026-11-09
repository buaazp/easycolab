#!/usr/bin/env python3
"""
Local Headless Google Colab Bridge for EasyColab macOS App.
Powered by google-colab-cli (inspired by FireTable/comfy-colab-kit).
Supports:
  - auth_status : Check OAuth login state, real CU balance, hourly burn rate, and active VMs
  - auth_url    : Generate Google OAuth2 authorization URL for 1-click browser login
  - auth_code   : Exchange Google authorization code and save ~/.config/colab-cli/token.json
  - wake        : Provision/reuse Colab GPU VM, deploy the server, and return its public URL
  - keepalive   : Refresh Colab runtime proxy & kernel activity while active
  - stop_all    : Unassign and terminate all active Colab VMs on the account (verify 0 CU/hr burn)
"""
import os
import re
import sys
import json
import time
import uuid
import argparse
import urllib.request
from importlib import resources
from easycolab_tunnel import read_tunnel_config

import requests
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow


def _ensure_utf8_stdio():
    """确保 Windows / macOS 子进程管道输出始终采用 UTF-8 编码，避免 emoji 在 GBK 代码页下抛出 UnicodeEncodeError"""
    for stream_name in ("stdout", "stderr"):
        stream = getattr(sys, stream_name, None)
        if stream is not None and hasattr(stream, "reconfigure"):
            try:
                stream.reconfigure(encoding="utf-8", errors="replace")
            except Exception:
                pass


_ensure_utf8_stdio()


def _sync_macos_system_proxies_to_env():
    """
    macOS 原生 GUI 应用启动子进程时默认不包含终端的 HTTP_PROXY / HTTPS_PROXY 环境变量，
    而 websocket-client (Jupyter 内核 WebSocket 通道) 仅从 os.environ 读取代理配置。
    此处自动读取 macOS / Windows 系统级代理 (scutil --proxy / Internet Settings / urllib.request.getproxies) 并注入环境变量。
    """
    try:
        proxies = urllib.request.getproxies()
        for k in ("http", "https"):
            if k in proxies and proxies[k]:
                os.environ.setdefault(f"{k}_proxy", proxies[k])
                os.environ.setdefault(f"{k.upper()}_PROXY", proxies[k])
    except Exception:
        pass


_sync_macos_system_proxies_to_env()

from colab_cli.auth import PUBLIC_SCOPES, TOKEN_CONFIG_PATH, REMOTE_REDIRECT_URI
from colab_cli.common import state
from colab_cli.client import Accelerator, Variant, Shape, resolve_assign_shape, PostAssignmentResponse, ColabRequestError
from colab_cli.state import SessionState
from colab_cli.runtime import ColabRuntime
from colab_cli.contents import ContentsClient


def _load_client_config() -> dict:
    cfg_path = os.path.expanduser("~/.colab-cli-oauth-config.json")
    if os.path.exists(cfg_path):
        with open(cfg_path, "r", encoding="utf-8") as f:
            return json.load(f)
    res = resources.files("colab_cli").joinpath("oauth_config.json")
    return json.loads(res.read_text(encoding="utf-8"))


def _has_valid_token() -> bool:
    if not os.path.exists(TOKEN_CONFIG_PATH):
        return False
    try:
        creds = Credentials.from_authorized_user_file(TOKEN_CONFIG_PATH, PUBLIC_SCOPES)
        if creds and creds.valid:
            return True
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
            with open(TOKEN_CONFIG_PATH, "w", encoding="utf-8") as f:
                f.write(creds.to_json())
            return True
    except Exception:
        return False
    return False


PKCE_VERIFIER_PATH = os.path.expanduser("~/.config/colab-cli/pkce_verifier.txt")
ACCOUNT_PROFILE_CACHE_PATH = os.path.expanduser("~/.config/colab-cli/account_profile.json")


def _clear_local_session_store():
    """切换或退出 Google 账号时，清理本地缓存的旧账号 Colab 会话记录"""
    try:
        existing = state.store.list()
        if isinstance(existing, dict):
            for name in list(existing.keys()):
                state.store.remove(name)
    except Exception:
        pass
    state._client = None
    state._sessions = None


def _get_account_email() -> str:
    """获取当前绑定 Google 账号邮箱（按 refresh_token 指纹本地缓存，避免重复请求）"""
    if not os.path.exists(TOKEN_CONFIG_PATH):
        return ""
    try:
        creds = Credentials.from_authorized_user_file(TOKEN_CONFIG_PATH, PUBLIC_SCOPES)
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
            with open(TOKEN_CONFIG_PATH, "w", encoding="utf-8") as f:
                f.write(creds.to_json())
        tok_fp = (creds.refresh_token or creds.token or "")[-20:]
        if tok_fp and os.path.exists(ACCOUNT_PROFILE_CACHE_PATH):
            try:
                with open(ACCOUNT_PROFILE_CACHE_PATH, "r", encoding="utf-8") as cf:
                    cached = json.load(cf)
                if cached.get("fp") == tok_fp and cached.get("email"):
                    return str(cached["email"])
            except Exception:
                pass
        if creds and creds.token:
            r = requests.get(
                "https://www.googleapis.com/oauth2/v2/userinfo",
                headers={"Authorization": f"Bearer {creds.token}"},
                timeout=5,
            )
            if r.status_code == 200:
                email = str(r.json().get("email") or "").strip()
                if email and tok_fp:
                    os.makedirs(os.path.dirname(ACCOUNT_PROFILE_CACHE_PATH), exist_ok=True)
                    with open(ACCOUNT_PROFILE_CACHE_PATH, "w", encoding="utf-8") as cf:
                        json.dump({"fp": tok_fp, "email": email}, cf)
                return email
    except Exception:
        pass
    return ""


def cmd_auth_url():
    client_config = _load_client_config()
    flow = InstalledAppFlow.from_client_config(client_config, PUBLIC_SCOPES)
    flow.redirect_uri = REMOTE_REDIRECT_URI
    # 显式传入 select_account consent，强制弹出 Google 多账号选择器以支持自由切换账号
    auth_url, _ = flow.authorization_url(prompt="select_account consent", token_usage="remote")
    os.makedirs(os.path.dirname(PKCE_VERIFIER_PATH), exist_ok=True)
    if getattr(flow, "code_verifier", None):
        with open(PKCE_VERIFIER_PATH, "w", encoding="utf-8") as f:
            f.write(flow.code_verifier)
    print(json.dumps({"ok": True, "auth_url": auth_url}))


def cmd_auth_code(code: str):
    try:
        client_config = _load_client_config()
        flow = InstalledAppFlow.from_client_config(client_config, PUBLIC_SCOPES)
        flow.redirect_uri = REMOTE_REDIRECT_URI
        if os.path.exists(PKCE_VERIFIER_PATH):
            with open(PKCE_VERIFIER_PATH, "r", encoding="utf-8") as f:
                flow.code_verifier = f.read().strip()
        flow.fetch_token(code=code.strip())
        creds = flow.credentials
        _clear_local_session_store()
        for p in (ACCOUNT_PROFILE_CACHE_PATH, PKCE_VERIFIER_PATH):
            if os.path.exists(p):
                try:
                    os.remove(p)
                except Exception:
                    pass
        os.makedirs(os.path.dirname(TOKEN_CONFIG_PATH), exist_ok=True)
        with open(TOKEN_CONFIG_PATH, "w", encoding="utf-8") as f:
            f.write(creds.to_json())
        return cmd_auth_status()
    except Exception as e:
        print(json.dumps({"ok": False, "logged_in": False, "error": str(e)}))


def cmd_auth_logout():
    _clear_local_session_store()
    for p in (TOKEN_CONFIG_PATH, PKCE_VERIFIER_PATH, ACCOUNT_PROFILE_CACHE_PATH):
        if os.path.exists(p):
            try:
                os.remove(p)
            except Exception:
                pass
    print(json.dumps({"ok": True, "logged_in": False, "email": ""}))


def _safe_sync_sessions():
    for attempt in range(3):
        try:
            return state.sync_sessions()
        except Exception:
            if attempt == 2:
                cached = {s.name: s for s in state.store.list()}
                return cached, []
            time.sleep(1.2)


def cmd_auth_status():
    if not _has_valid_token():
        print(json.dumps({"ok": True, "logged_in": False}))
        return

    try:
        info = state.client.get_consumption_user_info()
        local_sessions, assignments = _safe_sync_sessions()
        name_by_ep = {s.endpoint: s.name for s in local_sessions.values()}
        sess_list = []
        for a in assignments:
            sess_list.append({
                "name": name_by_ep.get(a.endpoint, "colab-vm"),
                "endpoint": a.endpoint,
                "accelerator": a.accelerator.value,
                "variant": a.variant.name,
                "shape": a.machine_shape.name,
            })

        email = _get_account_email()
        print(json.dumps({
            "ok": True,
            "logged_in": True,
            "email": email,
            "paid_balance": round(float(info.paid_compute_units_balance), 2),
            "burn_rate_hourly": round(float(info.consumption_rate_hourly), 2),
            "active_assignments": int(info.assignments_count),
            "sessions": sess_list,
        }))
    except Exception as e:
        print(json.dumps({
            "ok": False,
            "logged_in": True,
            "email": _get_account_email(),
            "error": str(e),
        }))


def _build_rclone_drive_conf() -> str:
    """
    优先读取独立 Drive 授权配置，否则复用 Google Colab CLI OAuth 凭据 (含 drive.file 权限域)，
    生成云端 rclone Google Drive 配置，使无浏览器唤醒的 G4 实例也能自动挂载/同步 Google Drive，
    持久化保存 ComfyUI 自定义节点、模型与工作流。
    """
    dedicated_path = os.environ.get("EASYCOLAB_RCLONE_CONFIG", "").strip()
    drive_config_path = os.path.expanduser(dedicated_path or "~/.config/easycolab/drive-rclone.conf")
    if dedicated_path or os.path.isfile(drive_config_path):
        import configparser
        import io

        def config_failure(reason):
            raise RuntimeError(f"独立 Drive 配置不可用：{reason} 不会回退使用 Colab OAuth 凭据。") from None

        try:
            with open(drive_config_path, encoding="utf-8-sig") as stream:
                config_text = stream.read()
        except FileNotFoundError:
            config_failure("找不到配置文件，请检查 EASYCOLAB_RCLONE_CONFIG 或 ~/.config/easycolab/drive-rclone.conf。")
        except (OSError, UnicodeError):
            config_failure("无法读取配置文件，请检查权限及 UTF-8 编码。")
        if any(line.strip().startswith("RCLONE_ENCRYPT_V") for line in config_text.splitlines()):
            config_failure("配置文件已加密，请用 rclone 为 EasyColab 单独创建未加密且仅本用户可读的配置。")
        config = configparser.ConfigParser(interpolation=None)
        try:
            config.read_string(config_text)
        except configparser.Error:
            config_failure("不是有效的 rclone INI 配置；请通过 rclone config 保存，不要粘贴授权网页或 JSON 客户端文件。")
        if config.has_section("easycolab_gdrive"):
            section = config["easycolab_gdrive"]
            if section.get("type") != "drive":
                config_failure("easycolab_gdrive 的类型必须为 drive。")
        else:
            drive_remotes = [name for name in config.sections() if config[name].get("type") == "drive"]
            if not drive_remotes:
                config_failure("未找到 Google Drive remote，请在 rclone config 中创建 Google Drive 类型的 remote。")
            if len(drive_remotes) > 1:
                config_failure("发现多个 Drive remote，请将要使用的一个命名为 easycolab_gdrive，避免连接错误的云盘。")
            section = config[drive_remotes[0]]
        try:
            token_data = json.loads(section.get("token") or "{}")
        except ValueError:
            config_failure("token 授权数据不是有效 JSON，请用 rclone config reconnect 重新授权该 remote，不要手填 Token。")
        if not isinstance(token_data, dict) or not isinstance(token_data.get("refresh_token", ""), str):
            config_failure("token 授权数据格式错误，请用 rclone config reconnect 重新授权该 remote。")
        if not token_data.get("refresh_token", "").strip():
            config_failure(
                "Google Drive 授权尚未完成，缺少 refresh_token；仅填写 Client ID / Secret 不算授权成功。"
                "个人自用可在 Google Auth Platform「目标对象」保持「测试」并添加自己的账号为测试用户，"
                "无需先通过品牌验证，再用 rclone config reconnect --config <配置文件> \"<remote 名称>:\" 完成浏览器授权。"
                "测试授权约 7 天到期，届时需重新授权。"
            )
        selected_config = configparser.ConfigParser(interpolation=None)
        selected_config["easycolab_gdrive"] = {
            key: section[key] for key in ("type", "client_id", "client_secret", "scope", "token", "root_folder_id", "team_drive")
            if key in section
        }
        output = io.StringIO()
        selected_config.write(output)
        return output.getvalue()

    if not os.path.exists(TOKEN_CONFIG_PATH):
        return ""
    try:
        creds = Credentials.from_authorized_user_file(TOKEN_CONFIG_PATH, PUBLIC_SCOPES)
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
            with open(TOKEN_CONFIG_PATH, "w", encoding="utf-8") as f:
                f.write(creds.to_json())
        raw = json.loads(creds.to_json())
        scopes = raw.get("scopes") or []
        drive_scope = "drive" if any(s.endswith("/drive") for s in scopes) else (
            "drive.file" if any("drive.file" in s for s in scopes) else ""
        )
        if not drive_scope or not raw.get("token") or not raw.get("refresh_token"):
            return ""
        tok_obj = {
            "access_token": raw["token"],
            "token_type": "Bearer",
            "refresh_token": raw["refresh_token"],
        }
        if raw.get("expiry"):
            tok_obj["expiry"] = raw["expiry"]
        lines = [
            "[easycolab_gdrive]",
            "type = drive",
            f"client_id = {raw.get('client_id', '')}",
            f"client_secret = {raw.get('client_secret', '')}",
            f"scope = {drive_scope}",
            f"token = {json.dumps(tok_obj, separators=(',', ':'))}",
            "",
        ]
        return "\n".join(lines)
    except Exception:
        return ""


def cmd_stop_all():
    if not _has_valid_token():
        print(json.dumps({"ok": False, "error": "尚未登录 Google Colab CLI"}))
        return

    try:
        local_sessions, assignments = state.sync_sessions()
        stopped_count = 0
        for s in list(local_sessions.values()):
            try:
                rt = ColabRuntime(s.url, s.token, kernel_id=s.kernel_id)
                try:
                    rt.execute_code(
                        "import urllib.request\n"
                        "try:\n"
                        "    urllib.request.urlopen(urllib.request.Request("
                        "'http://127.0.0.1:7860/minimax_api/comfyui/sync_drive', "
                        "data=b'{}', headers={'Content-Type':'application/json'}, method='POST'), timeout=18)\n"
                        "except Exception:\n"
                        "    pass\n",
                        allow_stdin=False,
                        timeout=22,
                    )
                except Exception:
                    pass
                rt.stop(shutdown_kernel=True)
            except Exception:
                pass
            try:
                state.client.unassign(s.endpoint)
                stopped_count += 1
            except Exception:
                pass
            state.store.remove(s.name)

        # 同时清理所有未在本地登记的云端孤儿实例 (Orphan VMs)
        for a in assignments:
            try:
                state.client.unassign(a.endpoint)
                stopped_count += 1
            except Exception:
                pass

        info = state.client.get_consumption_user_info()
        print(json.dumps({
            "ok": True,
            "stopped_count": stopped_count,
            "paid_balance": round(float(info.paid_compute_units_balance), 2),
            "burn_rate_hourly": round(float(info.consumption_rate_hourly), 2),
            "active_assignments": int(info.assignments_count),
            "message": f"🛑 已彻底释放全部云端实例！当前计费速率: {info.consumption_rate_hourly:.2f} CU/小时",
        }))
    except Exception as e:
        print(json.dumps({"ok": False, "error": str(e)}))


def _wait_for_runtime_ready(session: SessionState, timeout_s: int = 45) -> bool:
    """
    等待新分配的 Colab 容器内部 Jupyter Server (/api/kernels) 完成启动。
    规避容器刚启动前几秒出现的 SSLEOFError / ConnectionReset / 502 / 503。
    若检测到 404 (实例如已被销毁)，立即返回 False 以便重新分配新实例。
    """
    base_url = session.url.rstrip("/")
    probe_url = f"{base_url}/api/kernels"
    headers = {
        "Accept": "application/json",
        "X-Colab-Client-Agent": "colab-cli",
        "X-Colab-Runtime-Proxy-Token": session.token,
        "Authorization": f"Bearer {session.token}",
    }
    params = {"authuser": "0", "colab-runtime-proxy-token": session.token}
    deadline = time.time() + timeout_s
    not_found_count = 0

    while time.time() < deadline:
        try:
            r = requests.get(probe_url, headers=headers, params=params, timeout=8)
            if r.status_code == 200:
                return True
            if r.status_code in (404, 410):
                not_found_count += 1
                if not_found_count >= 2:
                    return False
        except requests.exceptions.RequestException:
            pass
        time.sleep(2.0)
    return False


GPU_ACCEL_MAP = {
    "h100": Accelerator.H100,
    "g4": Accelerator.G4,
    "a100": Accelerator.A100,
    "l4": Accelerator.L4,
    "t4": Accelerator.T4,
}

# G4 (RTX PRO 6000 Blackwell 96GB)、H100、L4 在 Colab 后端均为固定单规格大内存实例，传 shape=hm 会报 400 Bad Request
SINGLE_SHAPE_GPUS = frozenset({Accelerator.G4, Accelerator.H100, Accelerator.L4})


def _resolve_gpu_accel(gpu_type: str) -> Accelerator:
    return GPU_ACCEL_MAP.get((gpu_type or "g4").strip().lower(), Accelerator.G4)


def _allocate_fresh_session(session_name: str, gpu_type: str) -> SessionState:
    accel = _resolve_gpu_accel(gpu_type)
    shape = None if accel in SINGLE_SHAPE_GPUS else resolve_assign_shape(accel, high_mem=True)
    gpu_desc = "G4 (RTX PRO 6000 · 96GB)" if accel == Accelerator.G4 else accel.value
    print(f"WAKE_LOG: 🚀 正在向 Google Colab 申请分配 {gpu_desc} 实例...", flush=True)
    try:
        res = state.client.assign(uuid.uuid4(), variant=Variant.GPU, accelerator=accel, shape=shape)
    except ColabRequestError as req_err:
        if shape is not None and getattr(getattr(req_err, "response", None), "status_code", None) == 400:
            shape = None
            res = state.client.assign(uuid.uuid4(), variant=Variant.GPU, accelerator=accel, shape=None)
        else:
            raise
    if isinstance(res, PostAssignmentResponse):
        token = res.runtime_proxy_info.token
        url = res.runtime_proxy_info.url
        endpoint = res.endpoint
        exp = res.runtime_proxy_info.expires_at()
    else:
        token = res.runtime_proxy_info.token if hasattr(res, "runtime_proxy_info") else getattr(res, "runtime_proxy_token", "")
        url = res.runtime_proxy_info.url if hasattr(res, "runtime_proxy_info") else ""
        endpoint = res.endpoint
        exp = res.runtime_proxy_info.expires_at() if hasattr(res, "runtime_proxy_info") else None

    s = SessionState(
        name=session_name,
        token=token,
        url=url,
        endpoint=endpoint,
        token_expires_at=exp,
        variant=Variant.GPU.value,
        accelerator=accel.value,
        machine_shape=Shape.HIGH_RAM.name if shape == Shape.HIGH_RAM else Shape.STANDARD.name,
    )
    state.store.add(s)
    print(f"WAKE_LOG: ✅ 成功分配 {accel.value} 云端虚拟机！正在等待容器内核就绪...", flush=True)
    return s


def _upload_tunnel_config(contents, public_url, tunnel_token):
    import tempfile

    tunnel_fd, tunnel_path = tempfile.mkstemp(prefix="easycolab_tunnel_", suffix=".json")
    try:
        with os.fdopen(tunnel_fd, "w", encoding="utf-8") as tunnel_file:
            json.dump({"EASYCOLAB_PUBLIC_URL": public_url, "CLOUDFLARE_TUNNEL_TOKEN": tunnel_token}, tunnel_file)
        contents.upload(tunnel_path, "content/.easycolab_tunnel.json")
    except Exception:
        raise RuntimeError("无法上传隧道配置 (failed to upload tunnel configuration)") from None
    finally:
        os.remove(tunnel_path)


def cmd_wake(gpu_type: str, app_py_path: str):
    """
    无浏览器一键唤醒 Colab GPU 并自动部署 EasyColab 多模型服务端：
    1. 幂等检查：若已有运行中的会话且探活成功则直接复用，否则自动清理失效会话并分配新实例
    2. 等待容器 Jupyter 端点 (/api/kernels) TLS/HTTP 握手就绪，规避 SSLEOFError
    3. 上传本地最新 app.py、easycolab_tunnel.py 和临时隧道配置
    4. 在远端内核安装依赖并后台拉起 app.py，提取就绪的自定义域名或 gradio.live 地址
    """
    try:
        public_url, tunnel_token = read_tunnel_config(os.environ)
    except ValueError as config_error:
        print(f"WAKE_ERROR: {config_error}", flush=True)
        return

    if not _has_valid_token():
        print("WAKE_ERROR: 尚未授权登录 Google 账号，请先点击「🔑 绑定账号」", flush=True)
        return

    tunnel_module_path = os.path.join(os.path.dirname(os.path.abspath(app_py_path)), "easycolab_tunnel.py")
    vllm_module_path = os.path.join(os.path.dirname(os.path.abspath(app_py_path)), "easycolab_vllm.py")
    transfer_module_path = os.path.join(os.path.dirname(os.path.abspath(app_py_path)), "easycolab_transfer.py")
    monitor_module_path = os.path.join(os.path.dirname(os.path.abspath(app_py_path)), "easycolab_monitor.py")
    sglang_module_path = os.path.join(os.path.dirname(os.path.abspath(app_py_path)), "easycolab_sglang.py")
    if not all(os.path.isfile(path) for path in (app_py_path, tunnel_module_path, vllm_module_path, transfer_module_path, monitor_module_path, sglang_module_path)):
        print("WAKE_ERROR: 缺少服务端 Python 资源，请重新编译或更新客户端 (missing server resources)", flush=True)
        return

    try:
        rclone_conf_text = _build_rclone_drive_conf()
        session_name = "easycolab"
        print("WAKE_LOG: 🔍 正在检查账号下已有的 Colab 实例...", flush=True)
        local_sessions, assignments = _safe_sync_sessions()

        target_session = (
            local_sessions.get(session_name)
            or local_sessions.get("aevix")
            or local_sessions.get("minimax")
        )
        if target_session:
            session_name = target_session.name
        elif local_sessions:
            target_session = list(local_sessions.values())[0]
            session_name = target_session.name

        # 若本地未记录但云端已有活跃分配，直接纳管该云端实例
        if not target_session and assignments:
            a = assignments[0]
            target_session = SessionState(
                name=session_name,
                token=a.runtime_proxy_info.token,
                url=a.runtime_proxy_info.url,
                endpoint=a.endpoint,
                token_expires_at=a.runtime_proxy_info.expires_at(),
                variant=Variant.GPU.value,
                accelerator=a.accelerator.value,
                machine_shape=Shape.HIGH_RAM.name if a.machine_shape == Shape.HIGH_RAM else Shape.STANDARD.name,
            )
            state.store.add(target_session)

        requested_accel = _resolve_gpu_accel(gpu_type)
        if target_session:
            cur_acc = (target_session.accelerator or "").strip().upper()
            if cur_acc != requested_accel.value.upper():
                print(
                    f"WAKE_LOG: 🔄 当前已分配实例型号为 [{cur_acc or 'CPU'}]，正在释放并切换为您选择的 [{requested_accel.value}]...",
                    flush=True,
                )
                try:
                    state.client.unassign(target_session.endpoint)
                except Exception:
                    pass
                state.prune_session(target_session.name)
                target_session = None
            else:
                print(f"WAKE_LOG: ♻️ 正在检查已有实例 [{target_session.name}] ({target_session.accelerator}) 连通性...", flush=True)
                if not _wait_for_runtime_ready(target_session, timeout_s=15):
                    print("WAKE_LOG: ⚠️ 旧实例已失效或正在销毁，正在自动清理并重新分配新实例...", flush=True)
                    try:
                        state.client.unassign(target_session.endpoint)
                    except Exception:
                        pass
                    state.prune_session(target_session.name)
                    target_session = None

        if not target_session:
            target_session = _allocate_fresh_session(session_name, gpu_type)
            if not _wait_for_runtime_ready(target_session, timeout_s=50):
                print("WAKE_LOG: ⏳ 容器仍在初始化，继续尝试连接内核...", flush=True)

        print("WAKE_LOG: 正在上传最新多模型开源服务端代码 (app.py)...", flush=True)
        contents = ContentsClient(target_session)
        contents.upload(tunnel_module_path, "content/easycolab_tunnel.py")
        contents.upload(vllm_module_path, "content/easycolab_vllm.py")
        contents.upload(transfer_module_path, "content/easycolab_transfer.py")
        contents.upload(monitor_module_path, "content/easycolab_monitor.py")
        contents.upload(sglang_module_path, "content/easycolab_sglang.py")
        for up_attempt in range(4):
            try:
                contents.upload(app_py_path, "content/app.py")
                break
            except Exception as up_err:
                if up_attempt == 3:
                    raise up_err
                time.sleep(2.5)

        if rclone_conf_text:
            import tempfile
            tmp_rc_fd, tmp_rc_path = tempfile.mkstemp(prefix="easycolab_rc_", suffix=".conf")
            try:
                with os.fdopen(tmp_rc_fd, "w", encoding="utf-8") as rcf:
                    rcf.write(rclone_conf_text)
                os.chmod(tmp_rc_path, 0o600)
                contents.upload(tmp_rc_path, "content/.easycolab_rclone.conf")
            except Exception:
                raise RuntimeError("上传 Drive 挂载凭据失败，请检查连接后重试；不会继续以临时磁盘部署。") from None
            finally:
                if os.path.exists(tmp_rc_path):
                    try:
                        os.remove(tmp_rc_path)
                    except Exception:
                        pass
        else:
            print("WAKE_LOG: 未生成 Drive 凭据；云端必须已有有效的 Drive 挂载，否则部署将停止。", flush=True)

        _upload_tunnel_config(contents, public_url, tunnel_token)

        print("WAKE_LOG: 正在云端配置 Google Drive 持久化、多模型引擎并启动隧道 (约需 40~90 秒)...", flush=True)
        boot_code = r"""
import os, sys, time, re, shutil, subprocess, json, runpy

redact_diagnostic = runpy.run_path("/content/easycolab_tunnel.py")["redact_diagnostic"]

tunnel_stage = "/content/.easycolab_tunnel.json"
if not os.path.isfile(tunnel_stage):
    raise RuntimeError("隧道配置缺失，请重新唤醒部署 (missing tunnel configuration)")
os.chmod(tunnel_stage, 0o600)
try:
    with open(tunnel_stage, encoding="utf-8") as tunnel_file:
        tunnel_config = json.load(tunnel_file)
finally:
    os.remove(tunnel_stage)
app_env = os.environ.copy()
app_env.update(tunnel_config)
custom_domain = bool(tunnel_config["EASYCOLAB_PUBLIC_URL"])
diagnostic_secrets = (tunnel_config["CLOUDFLARE_TUNNEL_TOKEN"],)

# 0. 配置无网页模式下的 Google Drive 云盘自动挂载/高速同步 (供模型库与 ComfyUI 节点持久化)
rc_stage = "/content/.easycolab_rclone.conf"
if os.path.exists(rc_stage):
    rc_dir = os.path.expanduser("~/.config/rclone")
    os.makedirs(rc_dir, mode=0o700, exist_ok=True)
    rc_dst = os.path.join(rc_dir, "rclone.conf")
    shutil.move(rc_stage, rc_dst)
    os.chmod(rc_dst, 0o600)

def drive_mount_ready():
    return os.path.isdir("/content/drive/MyDrive") and (
        os.path.ismount("/content/drive") or os.path.ismount("/content/drive/MyDrive")
    )

def drive_mount_failure(stage, diagnostic="", external=False):
    if "SERVICE_DISABLED" in diagnostic or "accessNotConfigured" in diagnostic or "quota project" in diagnostic:
        reason = (
            "Google Drive API 返回 403：当前 OAuth 项目未启用 Drive API 或缺少配额项目。"
            "Colab 登录成功不代表 Drive 可用；请配置独立 drive-rclone.conf，或使用笔记本官方 Drive 挂载。"
        )
    elif "invalid_grant" in diagnostic or "invalid_token" in diagnostic or "unauthorized_client" in diagnostic:
        reason = "Drive 授权已失效，请重新授权独立 rclone Drive 配置后再部署。"
    elif "fusermount3" in diagnostic and ("not found" in diagnostic or "No such file" in diagnostic):
        reason = "缺少 FUSE3 挂载工具 fusermount3；旧版 fusermount 不能替代，请更新客户端后重新部署以自动安装 fuse3。"
    else:
        reason = (diagnostic if not external else "") or "请检查 Drive 授权、网络和云端 /content/easycolab_drive_mount.log 挂载日志。"
    raise RuntimeError(f"Google Drive {stage}失败：{reason} 不会回退临时磁盘；已有实例未释放。")

if not drive_mount_ready():
    if not os.path.isfile(os.path.expanduser("~/.config/rclone/rclone.conf")):
        drive_mount_failure("配置", "未找到 Drive 凭据，请配置独立 rclone Drive 授权或运行笔记本挂载步骤。")
    if not os.path.exists("/dev/fuse"):
        drive_mount_failure("挂载", "当前运行时缺少 /dev/fuse 设备，请使用支持 FUSE 挂载的运行时。")
    if not shutil.which("fusermount3"):
        if os.geteuid() != 0 or not shutil.which("apt-get"):
            drive_mount_failure("安装 FUSE3", "缺少 fusermount3 且无法自动安装，请先安装 fuse3 系统包；旧版 fusermount 不能替代。")
        print("WAKE_LOG: 正在安装 FUSE3 挂载依赖 (fusermount3)...", flush=True)
        install_env = os.environ.copy()
        install_env["DEBIAN_FRONTEND"] = "noninteractive"
        try:
            update_result = subprocess.run(
                ["apt-get", "update", "-qq"], capture_output=True, text=True, env=install_env, timeout=90,
            )
            if update_result.returncode:
                drive_mount_failure("安装 FUSE3", "apt 软件源更新失败，请检查运行时出站网络及 apt 软件源。")
            fuse_result = subprocess.run(
                ["apt-get", "install", "-y", "--no-install-recommends", "fuse3"],
                capture_output=True, text=True, env=install_env, timeout=90,
            )
        except subprocess.TimeoutExpired:
            drive_mount_failure("安装 FUSE3", "apt 操作超时，请检查出站网络或等待其他包管理任务结束后再试。")
        if fuse_result.returncode or not shutil.which("fusermount3"):
            drive_mount_failure("安装 FUSE3", "fuse3 安装未成功或找不到 fusermount3，请检查 apt 包管理器状态后重试。")
    if not shutil.which("rclone"):
        install_result = subprocess.run(
            ["bash", "-lc", "curl -fsSL https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip && unzip -q -o /tmp/rclone.zip -d /tmp && cp /tmp/rclone-*-linux-amd64/rclone /usr/local/bin/rclone && chmod +x /usr/local/bin/rclone && rm -rf /tmp/rclone*"],
            capture_output=True, text=True, timeout=90,
        )
        if install_result.returncode or not shutil.which("rclone"):
            drive_mount_failure("安装 rclone", install_result.stderr, external=True)
    print("WAKE_LOG: 正在验证 Google Drive API 访问权限...", flush=True)
    try:
        drive_probe = subprocess.run(
            ["rclone", "mkdir", "easycolab_gdrive:EasyColab_Drive", "--retries", "1", "--low-level-retries", "1", "--contimeout", "10s", "--timeout", "20s"],
            capture_output=True, text=True, timeout=35,
        )
    except subprocess.TimeoutExpired:
        drive_mount_failure("API 检查", "Drive API 请求超时，请检查出站网络。")
    if drive_probe.returncode:
        drive_mount_failure("API 检查", drive_probe.stderr, external=True)
    mount_path = "/content/drive/MyDrive"
    os.makedirs(mount_path, exist_ok=True)
    if os.listdir(mount_path):
        drive_mount_failure("挂载", "挂载目录已有本地文件，请先备份并清空该目录；不会覆盖已有文件。")
    mount_log_path = "/content/easycolab_drive_mount.log"
    mount_log_fd = os.open(mount_log_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(mount_log_fd, "w") as mount_log:
        os.chmod(mount_log_path, 0o600)
        prepare_monitor = runpy.run_path("/content/easycolab_transfer.py")["prepare_mount_monitor"]
        monitor_args, mount_env = prepare_monitor(mount_path, "easycolab_gdrive:EasyColab_Drive")
        mount_process = subprocess.Popen(
            [
                "rclone", "mount", "easycolab_gdrive:EasyColab_Drive", mount_path,
                "--vfs-cache-mode", "writes", "--vfs-write-back", "3s",
                "--dir-cache-time", "15s", "--drive-chunk-size", "64M", "--buffer-size", "32M",
            ] + monitor_args,
            env=mount_env, stdout=mount_log, stderr=subprocess.STDOUT,
        )
        mount_env.clear()
    try:
        deadline = time.monotonic() + 45
        while time.monotonic() < deadline:
            if drive_mount_ready():
                break
            if mount_process.poll() is not None:
                break
            time.sleep(0.5)
        if not drive_mount_ready():
            with open(mount_log_path, errors="replace") as mount_log:
                diagnostic = mount_log.read()[-4000:]
            drive_mount_failure("挂载", diagnostic or "rclone 未在 45 秒内建立挂载。", external=bool(diagnostic))
    except BaseException:
        if mount_process.poll() is None:
            mount_process.terminate()
            try:
                mount_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                mount_process.kill()
                mount_process.wait(timeout=5)
        raise

app_env["EASYCOLAB_REQUIRE_DRIVE"] = "1"
print("WAKE_LOG: ✅ Google Drive 挂载已验证；模型保存至 /content/drive/MyDrive/models。", flush=True)

# 1. 如果尚未安装 DiffSynth-Studio，自动快速安装 (含最新 transformers 以支持 Qwen3.8-27B)
if not os.path.exists("/content/DiffSynth-Studio"):
    print("正在克隆 DiffSynth-Studio...", flush=True)
    subprocess.run(["git", "clone", "--depth", "1", "https://github.com/modelscope/DiffSynth-Studio.git", "/content/DiffSynth-Studio"], check=True)
    subprocess.run([sys.executable, "-m", "pip", "install", "-q", "-U", "transformers", "accelerate", "bitsandbytes", "huggingface_hub", "hf_transfer", "qwen-vl-utils", "einops", "kernels>=0.17.2,<0.18.0", "av", "gradio", "modelscope", "imageio", "imageio-ffmpeg", "scipy", "soundfile", "librosa"], check=True)
    subprocess.run([sys.executable, "-m", "pip", "install", "-q", "--no-deps", "fla-core", "flash-linear-attention"], check=False)
    subprocess.run([sys.executable, "-m", "pip", "install", "-q", "--no-deps", "--only-binary=:all:", "causal-conv1d"], check=False)
    subprocess.run([sys.executable, "-m", "pip", "install", "-q", "-e", "/content/DiffSynth-Studio"], check=True)
else:
    try:
        from fla.ops.gated_delta_rule import chunk_gated_delta_rule  # noqa: F401
        import kernels  # noqa: F401
    except Exception:
        subprocess.run([sys.executable, "-m", "pip", "install", "-q", "einops", "kernels>=0.17.2,<0.18.0"], check=False)
        subprocess.run([sys.executable, "-m", "pip", "install", "-q", "--no-deps", "--force-reinstall", "fla-core", "flash-linear-attention"], check=False)

# 2. 检查是否已有运行中的 app.py 或 llama-server，先清理旧进程释放 GPU 显存
subprocess.run(["pkill", "-f", "python.*/content/app.py"], check=False)
subprocess.run(["pkill", "-f", "cloudflared.*--tag easycolab-main=1"], check=False)
subprocess.run(["pkill", "-f", "llama-server"], check=False)
time.sleep(1)

# 3. 后台启动 /content/app.py 并等待公网地址就绪
log_path = "/content/easycolab_server.log"
if os.path.exists(log_path):
    os.remove(log_path)

with open(log_path, "w") as out_f:
    server_proc = subprocess.Popen([sys.executable, "-u", "/content/app.py"], cwd="/content", env=app_env, stdout=out_f, stderr=subprocess.STDOUT)
app_env.pop("CLOUDFLARE_TUNNEL_TOKEN", None)
tunnel_config.clear()

url_re = re.compile(r"^EASYCOLAB_READY_URL:(https://[^\s]+)$", re.MULTILINE)
found_url = None
for _ in range(90):
    time.sleep(2)
    if os.path.exists(log_path):
        txt = open(log_path, "r", errors="replace").read()
        m = url_re.search(txt)
        if m:
            found_url = m.group(1)
            break
    if server_proc.poll() is not None:
        break

if found_url:
    print("WAKE_URL:" + found_url, flush=True)
else:
    exit_code = server_proc.poll()
    failure = f"服务进程退出 (exit={exit_code})" if exit_code is not None else "服务启动超时 (180s)"
    if exit_code is None:
        server_proc.terminate()
        try:
            server_proc.wait(timeout=8)
        except subprocess.TimeoutExpired:
            server_proc.kill()
            server_proc.wait(timeout=5)
            subprocess.run(["pkill", "-f", "cloudflared.*--tag easycolab-main=1"], check=False)
    raw_log = open(log_path, "r", errors="replace").read() if os.path.exists(log_path) else "no log"
    tail = redact_diagnostic(raw_log, diagnostic_secrets)[-6000:]
    for log_line in tail.splitlines():
        print("WAKE_LOG: " + log_line, flush=True)
    detail = next((line for line in reversed(tail.splitlines()) if line.strip()), "no log")
    mode = "自定义域名启动失败，不会回退随机地址" if custom_domain else "启动失败"
    print(f"WAKE_ERROR: {mode}：{failure}。{detail}", flush=True)
diagnostic_secrets = ()
"""
        def _on_kid(kid):
            target_session.kernel_id = kid
            state.store.add(target_session)

        def _on_sid(sid):
            target_session.session_id = sid
            state.store.add(target_session)

        def _run_boot_on_runtime(use_saved_kernel: bool):
            rt = ColabRuntime(
                target_session.url,
                target_session.token,
                session_name=target_session.name,
                history=state.history,
                kernel_id=target_session.kernel_id if use_saved_kernel else None,
                session_id=target_session.session_id if use_saved_kernel else None,
                on_kernel_started=_on_kid,
                on_session_started=_on_sid,
            )
            try:
                return rt.execute_code(boot_code, allow_stdin=False, timeout=600)
            finally:
                try:
                    rt.stop()
                except Exception:
                    pass

        try:
            outputs = _run_boot_on_runtime(use_saved_kernel=True)
        except Exception:
            target_session.kernel_id = None
            target_session.session_id = None
            _upload_tunnel_config(contents, public_url, tunnel_token)
            outputs = _run_boot_on_runtime(use_saved_kernel=False)

        for out in outputs:
            if "text" in out:
                for line in out["text"].splitlines():
                    print(line, flush=True)
            elif out.get("output_type") == "error":
                print("WAKE_ERROR: " + out.get("evalue", "Execution error"), flush=True)

    except Exception as e:
        print(f"WAKE_ERROR: {str(e)}", flush=True)


def cmd_keepalive():
    """
    向活跃的 Colab Headless 实例发送官方 Runtime Proxy 探活与轻量 Jupyter 内核脉冲：
    由于 EasyColab 推理流量走 *.gradio.live 隧道，若长时间无 *.prod.r.colab.dev 代理流量且内核 last_activity 静止，
    Colab 后台闲置回收器可能在连续生成第 2 条视频中途误判实例闲置并强制回收。
    本命令仅在客户端处于活跃窗口或正在执行生成任务时由 Mac 端定期调用。
    """
    if not _has_valid_token():
        print(json.dumps({"ok": True, "logged_in": False}))
        return

    try:
        local_sessions, assignments = _safe_sync_sessions()
        ep_map = {a.endpoint: a for a in assignments}
        touched = 0

        # 若云端有分配但本地无会话记录，自动纳管以便续期
        if not local_sessions and assignments:
            a0 = assignments[0]
            s_auto = SessionState(
                name="easycolab",
                token=a0.runtime_proxy_info.token,
                url=a0.runtime_proxy_info.url,
                endpoint=a0.endpoint,
                token_expires_at=a0.runtime_proxy_info.expires_at(),
                variant=Variant.GPU.value,
                accelerator=a0.accelerator.value,
                machine_shape=Shape.HIGH_RAM.name if a0.machine_shape == Shape.HIGH_RAM else Shape.STANDARD.name,
            )
            state.store.add(s_auto)
            local_sessions = {"easycolab": s_auto}

        for s in list(local_sessions.values()):
            if s.endpoint in ep_map:
                info_proxy = ep_map[s.endpoint].runtime_proxy_info
                s.token = info_proxy.token
                s.url = info_proxy.url
                s.token_expires_at = info_proxy.expires_at()
                state.store.add(s)

            if not s.url or not s.token:
                continue

            base_url = s.url.rstrip("/")
            headers = {
                "Accept": "application/json",
                "X-Colab-Client-Agent": "colab-cli",
                "X-Colab-Runtime-Proxy-Token": s.token,
                "Authorization": f"Bearer {s.token}",
            }
            params = {"authuser": "0", "colab-runtime-proxy-token": s.token}
            try:
                r = requests.get(f"{base_url}/api/kernels", headers=headers, params=params, timeout=10)
                if r.status_code == 200:
                    kernels = r.json() if r.text else []
                    active_kid = None
                    if isinstance(kernels, list) and kernels:
                        known_ids = [k.get("id") for k in kernels if k.get("id")]
                        active_kid = s.kernel_id if (s.kernel_id in known_ids) else known_ids[0]
                        # 清理多余的历史空转内核，仅保留主内核
                        for extra_id in known_ids:
                            if extra_id != active_kid:
                                try:
                                    requests.delete(
                                        f"{base_url}/api/kernels/{extra_id}",
                                        headers=headers,
                                        params=params,
                                        timeout=5,
                                    )
                                except Exception:
                                    pass

                    def _save_kid(kid, _s=s):
                        _s.kernel_id = kid
                        state.store.add(_s)

                    def _save_sid(sid, _s=s):
                        _s.session_id = sid
                        state.store.add(_s)

                    rt = ColabRuntime(
                        s.url,
                        s.token,
                        session_name=s.name,
                        kernel_id=active_kid,
                        session_id=s.session_id,
                        on_kernel_started=_save_kid,
                        on_session_started=_save_sid,
                    )
                    try:
                        rt.execute_code("_easycolab_hb = 1", allow_stdin=False, timeout=12)
                        touched += 1
                    finally:
                        try:
                            rt.stop(shutdown_kernel=False)
                        except Exception:
                            pass
            except Exception:
                pass

        info = state.client.get_consumption_user_info()
        print(json.dumps({
            "ok": True,
            "logged_in": True,
            "touched_kernels": touched,
            "paid_balance": round(float(info.paid_compute_units_balance), 2),
            "burn_rate_hourly": round(float(info.consumption_rate_hourly), 2),
            "active_assignments": int(info.assignments_count),
        }))
    except Exception as e:
        print(json.dumps({"ok": False, "logged_in": True, "error": str(e)}))


def main(argv=None):
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("auth_status")
    sub.add_parser("auth_url")
    sub.add_parser("auth_logout")
    sub.add_parser("drive_status")
    drive_import = sub.add_parser("drive_import")
    drive_import.add_argument("--client-json", required=True)
    drive_connect = sub.add_parser("drive_connect")
    drive_connect.add_argument("--full-access", action="store_true")

    p_code = sub.add_parser("auth_code")
    p_code.add_argument("code", type=str)

    p_wake = sub.add_parser("wake")
    p_wake.add_argument("--gpu", type=str, default="G4")
    p_wake.add_argument(
        "--app-py",
        type=str,
        default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "app.py"),
    )

    sub.add_parser("keepalive")
    sub.add_parser("stop_all")

    args = parser.parse_args(argv)
    if args.cmd in {"drive_status", "drive_import", "drive_connect"}:
        import easycolab_drive
        easycolab_drive.run_command(args.cmd, getattr(args, "client_json", None), getattr(args, "full_access", False))
    elif args.cmd == "auth_status":
        cmd_auth_status()
    elif args.cmd == "auth_url":
        cmd_auth_url()
    elif args.cmd == "auth_logout":
        cmd_auth_logout()
    elif args.cmd == "auth_code":
        cmd_auth_code(args.code)
    elif args.cmd == "wake":
        cmd_wake(args.gpu, args.app_py)
    elif args.cmd == "keepalive":
        cmd_keepalive()
    elif args.cmd == "stop_all":
        cmd_stop_all()


def run_cli(argv=None):
    """供独立 CLI 或打包后的 Windows exe (--bridge-cli) 子进程模式统一调用"""
    try:
        main(argv)
    finally:
        sys.stdout.flush()
        sys.stderr.flush()
        os._exit(0)


if __name__ == "__main__":
    run_cli()
