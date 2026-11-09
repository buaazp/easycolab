import atexit
from collections import deque
import json
import os
from pathlib import Path
import shutil
import signal
import socket
import subprocess
import sys
import threading
import time
import urllib.request

from easycolab_tunnel import redact_diagnostic


FLASH_NEXT_FILE_SIZES = dict(zip(
    [f"model-{shard:05d}-of-00017.safetensors" for shard in range(1, 18)],
    [
        5000950872, 102400512288, 5001866732, 5001596136, 5001604976,
        5001664808, 5002167076, 5001611952, 5001665048, 5001611176,
        5001611952, 4974531896, 5001639140, 5001611952, 5001611952,
        4597982420, 1271398528,
    ],
))
FLASH_NEXT_FILE_SIZES["model-mtp.safetensors"] = 5214305456
FLASH_NEXT_SPEC = {
    "id": "qwen38_flash_next_nvfp4",
    "name": "Qwen3.8-Flash-Next-Uncensored-NVFP4",
    "repo_id": "orcarouter/Qwen3.8-Flash-Next-Uncensored-NVFP4",
    "revision": "9c6f1345b523a9d9d70b41542a63b39e3c9b7ca6",
    "modality": "llm_vlm",
    "backend": "vllm",
    "gated": True,
    "category": "NVFP4 · 单卡 Blackwell 96GB · PLE CPU 卸载 · HF 授权",
    "approx_size_gb": 170.9,
    "file_sizes": FLASH_NEXT_FILE_SIZES,
    "files": [
        (filename, "MTP 权重（不默认启用投机解码）" if filename == "model-mtp.safetensors"
         else f"NVFP4 混合精度分片 {shard}/17")
        for shard, filename in enumerate(FLASH_NEXT_FILE_SIZES, 1)
    ],
}
_PROCESSES = set()


def validate_devices(devices):
    if not devices:
        raise RuntimeError("此 NVFP4 模型需要单张 RTX PRO 6000 Blackwell 96GB 或更大的 Blackwell GPU。")
    major, minor, memory = devices[0]
    if (major, minor) not in {(10, 0), (10, 3), (12, 0)}:
        raise RuntimeError(
            "NVFP4 需 Blackwell SM100/103/120；H100/H200、A100、L4、T4 不支持此运行方案。"
            "DGX Spark SM121 的专用补丁/跨节点方案未集成。"
        )
    if memory < 90:
        raise RuntimeError(
            "单卡 NVFP4 + PLE CPU 卸载需约 96GB 显卡（至少 90 GiB 总显存）；"
            "其余主权重仍约 70.7 GiB，消费级小显存卡不适用。"
        )


def validate_hardware(torch):
    if not sys.platform.startswith("linux"):
        raise RuntimeError("此 vLLM 后端需要 Linux CUDA 主机，不在 Mac 本机运行。")
    devices = [
        (*torch.cuda.get_device_capability(index), torch.cuda.get_device_properties(index).total_memory / 1024**3)
        for index in range(torch.cuda.device_count())
    ]
    validate_devices(devices)


def validate_memory(available_gib):
    if available_gib < 112:
        raise RuntimeError(
            f"系统可用内存仅 {available_gib:.1f} GiB；PLE 表约 95.4 GiB，"
            "此单卡方案至少需 112 GiB 可用 RAM（含约 16 GiB 余量）。"
            "请停止其他模型/ComfyUI，或换用高内存 G4 运行时。"
        )


def validate_context(context_length):
    if not 4096 <= context_length <= 32768:
        raise ValueError("单卡 96GB 初始配置仅支持 4K–32K 上下文，请调低上下文长度后重新加载。")


def validate_checkpoint(model_dir):
    with open(os.path.join(model_dir, "config.json"), encoding="utf-8") as stream:
        config = json.load(stream)
    if (config.get("model_type") != "qwen4_exp"
            or "Qwen4ExpForConditionalGeneration" not in config.get("architectures", [])
            or config.get("quantization_config", {}).get("quant_method") != "compressed-tensors"):
        raise RuntimeError("权重配置不是预期的 qwen4_exp / compressed-tensors，请重新下载固定版本。")


def stage_checkpoint(model_dir, report):
    from easycolab_transfer import find_rclone_mount

    mount = find_rclone_mount(model_dir)
    if not mount:
        return model_dir
    destination = Path(os.getcwd()) / "models" / FLASH_NEXT_SPEC["repo_id"]
    destination.mkdir(parents=True, exist_ok=True)
    if destination.is_symlink() or find_rclone_mount(str(destination.resolve())):
        raise RuntimeError("vLLM SSD 缓存目录指向云盘，请使用真实的实例本地磁盘目录。")
    with open(os.path.join(model_dir, ".easycolab-metadata.json"), encoding="utf-8") as stream:
        metadata = json.load(stream)
    files = metadata["files"]
    for name, size in files.items():
        if os.path.isabs(name) or os.path.normpath(name) != name or name.startswith("..") or not isinstance(size, int) or size <= 0:
            raise ValueError("Invalid checkpoint metadata path or size")
    for name in (*FLASH_NEXT_FILE_SIZES, *files, ".easycolab-metadata.json"):
        target = destination / name
        if target.is_symlink() or not target.resolve().is_relative_to(destination.resolve()):
            raise RuntimeError("vLLM SSD 缓存路径含软链接或越界路径，未修改；请检查本地缓存目录。")
    needed = sum(size for name, size in FLASH_NEXT_FILE_SIZES.items()
                 if not (destination / name).is_file() or (destination / name).stat().st_size != size)
    if shutil.disk_usage(destination).free < needed + 22 * 1024**3:
        raise RuntimeError(f"vLLM 本地 SSD 预热还需 {needed / 1024**3:.1f} GiB 权重空间及 22 GiB 余量；当前磁盘空间不足。不会删除云盘权重或静默用慢速 FUSE mmap。")
    if needed:
        report(f"正在将 {needed / 1024**3:.1f} GiB 权重从 Drive 预热至本地 SSD，避免 FUSE mmap 超时（云盘原件保留）...")
        command = ["rclone", "copy", mount["remote"], str(destination), "--size-only", "--transfers", "4", "--multi-thread-streams", "4", "--stats", "5s", "--stats-one-line", "--stats-log-level", "NOTICE"]
        for filename in FLASH_NEXT_FILE_SIZES:
            command.extend(["--include", "/" + filename])
        command.extend(["--exclude", "*"])
        _run_runtime_command(command, _runtime_environment(), 3600, "Drive 到本地 SSD 预热")
    for filename, size in FLASH_NEXT_FILE_SIZES.items():
        if not (destination / filename).is_file() or (destination / filename).stat().st_size != size:
            raise RuntimeError("本地 SSD 权重大小校验失败，请重试；云盘原件未修改。")
    for filename in (*files, ".easycolab-metadata.json"):
        target = destination / filename
        target.parent.mkdir(parents=True, exist_ok=True)
        temporary = target.with_name(target.name + ".staging")
        shutil.copyfile(os.path.join(model_dir, filename), temporary)
        os.replace(temporary, target)
    report("本地 SSD 权重与配置已就绪，开始 vLLM 加载；Drive 持久化副本保留。")
    return str(destination)


def _runtime_environment(offline=False, python_path=None):
    environment = os.environ.copy()
    for key in ("HF_TOKEN", "HUGGING_FACE_HUB_TOKEN", "CLOUDFLARE_TUNNEL_TOKEN", "TUNNEL_TOKEN", "PYTHONPATH", "PYTHONHOME"):
        environment.pop(key, None)
    if python_path:
        environment["PATH"] = str(Path(python_path).parent) + os.pathsep + environment.get("PATH", "")
    if not environment.get("CUDA_HOME"):
        nvcc = shutil.which("nvcc", path=environment.get("PATH"))
        if nvcc:
            environment["CUDA_HOME"] = str(Path(nvcc).resolve().parent.parent)
        elif os.path.isfile("/usr/local/cuda/bin/nvcc"):
            environment["CUDA_HOME"] = "/usr/local/cuda"
    if environment.get("CUDA_HOME"):
        environment["PATH"] += os.pathsep + os.path.join(environment["CUDA_HOME"], "bin")
    if offline:
        environment["HF_HUB_OFFLINE"] = "1"
        environment["TRANSFORMERS_OFFLINE"] = "1"
    return environment


def patched_qwen4_source(source, filename):
    if filename == "model.py":
        original = '"qkv_proj": ["q_proj", "k_proj", "v_proj", "indexer.index_qk_proj"],'
        replacement = '"qkv_proj": ["q_proj", "k_proj", "v_proj"],'
        if original not in source and replacement in source:
            return source
    elif filename == "qsa.py":
        original = "        self.fuse_indexer_projection = vllm_config.lora_config is None\n"
        replacement = (
            "        fused_quant_config = model.without_modelopt_fp4(quant_config)\n"
            "        projection_method = type(self.qkv_proj.quant_method)\n"
            "        self.fuse_indexer_projection = vllm_config.lora_config is None and (\n"
            "            fused_quant_config is None\n"
            "            or projection_method is type(self.indexer.index_qk_proj.quant_method)\n"
            "        )\n"
        )
        if replacement in source:
            return source
    else:
        raise ValueError("Unsupported compatibility source")
    if source.count(original) != 1:
        raise RuntimeError("vLLM Qwen4 源码与预期不符，未修改；请使用受支持的独立环境。")
    return source.replace(original, replacement, 1)


def patch_runtime_package():
    from importlib.metadata import version
    from importlib.util import find_spec

    if version("vllm") != "0.33.0":
        raise RuntimeError("兼容修复仅适用于 vLLM 0.33.0，不修改其他版本。")
    root = Path(find_spec("vllm").origin).parent / "models" / "qwen4_exp" / "nvidia"
    updates = []
    for filename in ("model.py", "qsa.py"):
        path = root / filename
        source = path.read_text()
        updated = patched_qwen4_source(source, filename)
        compile(updated, str(path), "exec")
        updates.append((path, source, updated))
    for path, source, updated in updates:
        if source == updated:
            continue
        backup = path.with_suffix(".py.easycolab-original")
        if not backup.exists():
            backup.write_text(source)
        temporary = path.with_suffix(".py.easycolab-tmp")
        temporary.write_text(updated)
        os.replace(temporary, path)
    print("Qwen4 QKV/indexer 混合精度兼容修复已验证。", flush=True)


def _run_runtime_command(command, environment, timeout, stage):
    process = subprocess.Popen(
        command, env=environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, encoding="utf-8", errors="replace", bufsize=1, start_new_session=True,
    )
    _PROCESSES.add(process)
    recent_logs = deque(maxlen=30)

    def drain_output():
        try:
            for line in process.stdout:
                clean = redact_diagnostic(line.rstrip())
                if clean:
                    recent_logs.append(clean[-1500:])
                    print("[vLLM 环境] " + clean[-1500:], flush=True)
        finally:
            process.stdout.close()

    log_thread = threading.Thread(target=drain_output, daemon=True)
    log_thread.start()
    try:
        try:
            exit_code = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            stop_server(process)
            log_thread.join(timeout=5)
            raise RuntimeError(f"{stage}超时（{timeout}s）。\n" + "\n".join(recent_logs)[-2400:]) from None
        log_thread.join(timeout=5)
        if exit_code:
            raise RuntimeError(f"{stage}失败（退出码 {exit_code}）。\n" + "\n".join(recent_logs)[-2400:])
    finally:
        if process.poll() is None:
            stop_server(process)
        _PROCESSES.discard(process)


def ensure_runtime(report):
    custom_python = os.environ.get("EASYCOLAB_VLLM_PYTHON", "").strip()
    python_path = custom_python or os.path.join(os.getcwd(), ".easycolab-vllm-venv", "bin", "python")
    if custom_python and not os.path.isfile(python_path):
        raise RuntimeError("EASYCOLAB_VLLM_PYTHON 必须指向已安装 vLLM 的独立 Python 可执行文件。")
    environment = _runtime_environment(python_path=python_path)
    if not custom_python:
        if sys.version_info < (3, 11):
            raise RuntimeError("vLLM 0.33.0 需要 Python 3.11+，请升级运行时或设置 EASYCOLAB_VLLM_PYTHON。")
        marker = Path(python_path).parent.parent / ".easycolab-runtime"
        runtime_version = "vllm==0.33.0 transformers==5.20.1 flashinfer-python==0.7.2.post1"
        if not os.path.isfile(python_path) or not marker.is_file() or marker.read_text() != runtime_version:
            report("正在创建独立 vLLM 环境（首次安装可能需数分钟，不修改现有 PyTorch）...")
            _run_runtime_command(
                [sys.executable, "-m", "venv", "--without-pip", str(marker.parent)],
                environment, 120, "创建独立 vLLM 环境",
            )
            report("正在安装独立 vLLM 依赖（不缓存大型 CUDA wheel，安装日志将实时显示）...")
            _run_runtime_command(
                [sys.executable, "-m", "pip", "--python", python_path, "install",
                 "--disable-pip-version-check", "--no-cache-dir", "pip", "vllm==0.33.0", "transformers==5.20.1", "flashinfer-python==0.7.2.post1"],
                environment, 1800, "安装独立 vLLM 依赖",
            )
            marker.write_text(runtime_version)
        report("正在校验 Qwen4 QKV/indexer 混合精度兼容修复（不修改权重）...")
        _run_runtime_command(
            [python_path, "-c", f"import sys; sys.path.insert(0, {str(Path(__file__).resolve().parent)!r}); from easycolab_vllm import patch_runtime_package; patch_runtime_package()"],
            environment, 60, "应用 Qwen4 混合精度修复",
        )
        kernel_probe = subprocess.run(
            [python_path, "-c", "from importlib.metadata import version; assert version('flashinfer-cubin') == version('flashinfer-python') == '0.7.2.post1'"],
            capture_output=True, text=True, env=environment, timeout=30,
        )
        if kernel_probe.returncode:
            report("正在安装匹配版本的 FlashInfer 预编译内核，避免运行时重复下载...")
            _run_runtime_command(
                [python_path, "-m", "pip", "install", "--disable-pip-version-check", "--no-cache-dir", "--no-deps",
                 "flashinfer-cubin==0.7.2.post1", "--index-url", "https://flashinfer.ai/whl"],
                environment, 900, "安装 FlashInfer 预编译内核",
            )
        jit_probe = subprocess.run(
            [python_path, "-c", (
                "from importlib.metadata import version, distributions; import torch; "
                "expected = '0.7.2.post1+cu' + torch.version.cuda.replace('.', ''); "
                "assert version('flashinfer-jit-cache') == expected; "
                "major, minor = torch.cuda.get_device_capability(0); "
                "prefix = f'flashinfer-jit-cache-sm{major}{minor}'; "
                "assert any(dist.metadata['Name'].lower().replace('_', '-').startswith(prefix) "
                "and dist.version == expected for dist in distributions())"
            )],
            capture_output=True, text=True, env=environment, timeout=60,
        )
        if jit_probe.returncode:
            report("正在安装当前 GPU 架构的 FlashInfer JIT 缓存（不下载全部架构）...")
            _run_runtime_command(
                [python_path, "-m", "flashinfer", "install-jit-cache-wheel", "--mode", "minimal"],
                {**environment, "PIP_NO_CACHE_DIR": "1"}, 900, "安装 FlashInfer JIT 缓存",
            )
    report("正在校验 vLLM qwen4_exp 架构与 Transformers 版本...")
    probe = subprocess.run(
        [python_path, "-c", (
            "from importlib.metadata import version; "
            "from packaging.version import Version; "
            "from vllm.model_executor.models import ModelRegistry; "
            "from vllm.config import EngramConfig; "
            "assert Version(version('transformers')) >= Version('5.16'); "
            "assert EngramConfig(cpu_offload=True).cpu_offload; "
            "assert 'Qwen4ExpForConditionalGeneration' in ModelRegistry.get_supported_archs()"
        )],
        capture_output=True, text=True, env=environment, timeout=120,
    )
    if probe.returncode:
        raise RuntimeError("vLLM 环境校验失败（需 qwen4_exp 与 Transformers ≥5.16）: " + redact_diagnostic(probe.stderr[-2400:]))
    return python_path


def build_command(python_path, model_dir, port, context_length):
    validate_context(context_length)
    return [
        python_path, "-m", "vllm.entrypoints.cli.main", "serve", model_dir,
        "--served-model-name", FLASH_NEXT_SPEC["repo_id"],
        "--host", "127.0.0.1", "--port", str(port),
        "--tensor-parallel-size", "1", "--trust-remote-code", "--enable-expert-parallel",
        "--engram-config", '{"cpu_offload":true}', "--safetensors-load-strategy", "lazy",
        "--enable-auto-tool-choice", "--tool-call-parser", "qwen3_coder",
        "--reasoning-parser", "qwen3", "--no-enable-flashinfer-autotune",
        "--max-model-len", str(context_length), "--max-num-seqs", "1",
        "--max-num-batched-tokens", "2048", "--enforce-eager",
        "--limit-mm-per-prompt", '{"image":2,"video":0}',
        "--gpu-memory-utilization", "0.90", "--kv-cache-dtype", "auto",
    ]


def stop_server(process):
    if process is None:
        return
    try:
        os.killpg(process.pid, signal.SIGTERM)
        process.wait(timeout=10)
    except ProcessLookupError:
        pass
    except subprocess.TimeoutExpired:
        pass
    finally:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait(timeout=10)
        _PROCESSES.discard(process)


def _cleanup_servers():
    for process in list(_PROCESSES):
        stop_server(process)


atexit.register(_cleanup_servers)


def start_server(model_dir, context_length, report):
    validate_checkpoint(model_dir)
    python_path = ensure_runtime(report)
    model_dir = stage_checkpoint(model_dir, report)
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        port = listener.getsockname()[1]
    report("正在启动单卡 vLLM NVFP4（PLE→CPU；BF16 KV；关闭 MTP/CUDA Graph；首次加载可能较慢）...")
    process = subprocess.Popen(
        build_command(python_path, model_dir, port, context_length),
        env=_runtime_environment(offline=True, python_path=python_path), stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, bufsize=1, start_new_session=True,
    )
    _PROCESSES.add(process)
    recent_logs = deque(maxlen=30)
    error_logs = deque(maxlen=10)

    def drain_output():
        for line in process.stdout:
            clean = redact_diagnostic(line.rstrip())
            if clean:
                recent_logs.append(clean[-1500:])
                if ("Error:" in clean or "Exception:" in clean) and clean not in error_logs:
                    error_logs.append(clean[-1500:])
                print("[vLLM] " + clean[-1500:], flush=True)

    log_thread = threading.Thread(target=drain_output, daemon=True)
    log_thread.start()
    base_url = f"http://127.0.0.1:{port}"
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    try:
        deadline = time.monotonic() + 1800
        while time.monotonic() < deadline and process.poll() is None:
            try:
                with opener.open(base_url + "/health", timeout=2) as response:
                    if response.status == 200:
                        return {
                            "backend": "vllm", "model_id": FLASH_NEXT_SPEC["id"],
                            "served_model": FLASH_NEXT_SPEC["repo_id"], "base_url": base_url,
                            "server_proc": process, "context_length": context_length,
                            "mode_label": f"Qwen3.8-Flash-Next · NVFP4 单卡/PLE CPU · {context_length // 1024}K",
                        }
            except (OSError, urllib.error.URLError):
                pass
            time.sleep(1)
        if process.poll() is not None:
            log_thread.join(timeout=5)
        reason = f"退出码 {process.returncode}" if process.poll() is not None else "启动超过 30 分钟"
        detail = "\n".join(recent_logs)[-2400:]
        if error_logs:
            detail = "\n".join(error_logs)[:1200] + "\n" + detail[-1200:]
        raise RuntimeError(f"vLLM 启动失败（{reason}），检查 CUDA 驱动、显存及运行时兼容性。\n" + detail)
    except BaseException:
        stop_server(process)
        raise
