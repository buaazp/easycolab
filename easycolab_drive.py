"""Desktop Drive OAuth and private rclone configuration, independent of Colab login."""

import configparser
import io
import json
import os
from pathlib import Path
import tempfile


CLIENT_PATH = Path.home() / ".config/easycolab/drive-oauth-client.json"
AUTH_URI = "https://accounts.google.com/o/oauth2/auth"
TOKEN_URI = "https://oauth2.googleapis.com/token"
DRIVE_SCOPE = "https://www.googleapis.com/auth/drive.file"


def config_path():
    return Path(os.path.expanduser(os.environ.get("EASYCOLAB_RCLONE_CONFIG", "").strip() or "~/.config/easycolab/drive-rclone.conf"))


def private_write(path, text):
    path = Path(path)
    path.parent.mkdir(parents=True, mode=0o700, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=path.parent, delete=False) as stream:
            temporary = stream.name
            os.chmod(temporary, 0o600)
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if temporary and os.path.exists(temporary):
            os.remove(temporary)


def read_config():
    config = configparser.ConfigParser(interpolation=None)
    path = config_path()
    if path.is_file():
        try:
            config.read_string(path.read_text(encoding="utf-8-sig"))
        except (OSError, ValueError, configparser.Error):
            raise RuntimeError("Drive 配置无法读取或已加密，请先备份并检查配置文件。") from None
    return config


def drive_section(config):
    if config.has_section("easycolab_gdrive"):
        if config["easycolab_gdrive"].get("type") != "drive":
            raise RuntimeError("easycolab_gdrive 不是 Google Drive 类型，未覆盖配置。")
        return "easycolab_gdrive"
    remotes = [name for name in config.sections() if config[name].get("type") == "drive"]
    if len(remotes) > 1:
        raise RuntimeError("存在多个 Drive，请将要连接的配置命名为 easycolab_gdrive。")
    return remotes[0] if remotes else "easycolab_gdrive"


def validate_client(data):
    client = data.get("installed") if isinstance(data, dict) else None
    if not isinstance(client, dict):
        raise ValueError("请选择 Google Cloud 下载的桌面应用 OAuth 客户端 JSON，不是 Web 应用或服务账号。")
    client_id, client_secret = client.get("client_id", ""), client.get("client_secret", "")
    if not isinstance(client_id, str) or not client_id.endswith(".apps.googleusercontent.com") or not isinstance(client_secret, str) or not client_secret.strip():
        raise ValueError("OAuth 客户端 ID 或 Secret 缺失，请重新下载桌面应用客户端 JSON。")
    if any(character.isspace() for character in client_id + client_secret):
        raise ValueError("OAuth 客户端字段格式无效。")
    if len(client_id) > 1024 or len(client_secret) > 4096:
        raise ValueError("OAuth 客户端字段过长。")
    return {"installed": {"client_id": client_id, "client_secret": client_secret, "auth_uri": AUTH_URI, "token_uri": TOKEN_URI}}


def import_client(path):
    try:
        if os.path.getsize(path) > 1024 * 1024:
            raise ValueError("Client JSON too large")
        with open(path, encoding="utf-8-sig") as stream:
            client = validate_client(json.load(stream))
    except (OSError, ValueError, TypeError):
        raise RuntimeError("导入失败：请选择 Google Cloud 的桌面应用 OAuth 客户端 JSON；旧配置未修改。") from None
    private_write(CLIENT_PATH, json.dumps(client))
    return {"ok": True, "client_configured": True, "message": "Drive 客户端已保存，请点击连接并完成浏览器授权。"}


def load_client(config):
    if CLIENT_PATH.is_file():
        try:
            return validate_client(json.loads(CLIENT_PATH.read_text()))
        except (OSError, ValueError, TypeError):
            raise RuntimeError("Drive OAuth 客户端配置无效，请重新导入桌面应用 JSON。") from None
    name = drive_section(config)
    if config.has_section(name):
        section = config[name]
        try:
            return validate_client({"installed": {"client_id": section.get("client_id", ""), "client_secret": section.get("client_secret", "")}})
        except ValueError:
            pass
    raise RuntimeError("请先导入自己的 Google 桌面应用 OAuth 客户端 JSON；Colab 内置登录不能替代 Drive 授权。")


def status():
    config = read_config()
    name = drive_section(config)
    try:
        load_client(config)
        configured = True
    except RuntimeError:
        configured = False
    saved = False
    if config.has_section(name):
        try:
            token = json.loads(config[name].get("token", "{}"))
            saved = isinstance(token, dict) and bool(token.get("refresh_token"))
        except ValueError:
            pass
    return {"ok": True, "client_configured": configured, "authorized": saved,
            "full_access": config.has_section(name) and config[name].get("scope") == "drive",
            "message": "已保存 Drive 授权（Testing 授权 7 天后需重连；未在线验证）。" if saved else (
                "客户端已配置，请连接 Google Drive。" if configured else "请先导入桌面应用 OAuth 客户端 JSON。")}


def connect(full_access=False):
    from google_auth_oauthlib.flow import InstalledAppFlow
    import requests

    config = read_config()
    name = drive_section(config)
    client = load_client(config)
    scope = "https://www.googleapis.com/auth/drive" if full_access else DRIVE_SCOPE
    flow = InstalledAppFlow.from_client_config(client, scopes=[scope], autogenerate_code_verifier=True)
    fetch_token = flow.fetch_token

    def bounded_fetch_token(**kwargs):
        return fetch_token(timeout=20, **kwargs)

    flow.fetch_token = bounded_fetch_token
    try:
        credentials = flow.run_local_server(
            host="127.0.0.1", port=0, open_browser=False, timeout_seconds=180,
            authorization_prompt_message="DRIVE_AUTH_URL:{url}",
            success_message="EasyColab: authorization received. You may close this tab and return to the app.",
            access_type="offline", prompt="consent", include_granted_scopes="false",
        )
        if not credentials.refresh_token:
            raise RuntimeError("missing refresh token")
        response = requests.get("https://www.googleapis.com/drive/v3/about", params={"fields": "storageQuota"},
                                headers={"Authorization": "Bearer " + credentials.token}, timeout=20)
        if response.status_code != 200:
            raise RuntimeError("Drive API unavailable")
    except Exception:
        raise RuntimeError("Drive 授权未完成或 API 验证失败；请确认已启用 Drive API、Testing 测试用户及浏览器授权。旧授权未修改。") from None
    token = {"access_token": credentials.token, "token_type": "Bearer", "refresh_token": credentials.refresh_token}
    if credentials.expiry:
        token["expiry"] = credentials.expiry.isoformat().replace("+00:00", "Z")
        if not token["expiry"].endswith("Z"):
            token["expiry"] += "Z"
    if not config.has_section(name):
        config.add_section(name)
    config[name].update(type="drive", client_id=client["installed"]["client_id"],
                        client_secret=client["installed"]["client_secret"], scope="drive" if full_access else "drive.file",
                        token=json.dumps(token, separators=(",", ":")))
    output = io.StringIO()
    config.write(output)
    private_write(config_path(), output.getvalue())
    return {"ok": True, "client_configured": True, "authorized": True,
            "message": "Google Drive 授权及 API 验证成功；重新唤醒部署后生效。Testing 授权约 7 天到期。"}


def run_command(command, client_json=None, full_access=False):
    try:
        result = import_client(client_json) if command == "drive_import" else (connect(full_access) if command == "drive_connect" else status())
    except (OSError, RuntimeError, ValueError):
        result = {"ok": False, "message": "Drive 操作失败：检查桌面应用 OAuth JSON、测试用户、Drive API 和授权超时；已有凭据未主动删除。"}
    print("DRIVE_RESULT:" + json.dumps(result, ensure_ascii=False), flush=True)
