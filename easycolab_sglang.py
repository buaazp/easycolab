"""Independent experimental Penny Royal backend; never rewrites the vLLM model/runtime."""

import argparse
import atexit
from collections import deque
import json
import os
from pathlib import Path
import re
import shutil
import socket
import subprocess
import sys
import threading
import time
import urllib.request

from easycolab_tunnel import redact_diagnostic
from easycolab_vllm import _run_runtime_command, stop_server


PENNY_REVISION = "202f266be2d46453e098792fa39057e859fb8095"
PENNY_REPOSITORY = "https://github.com/jpezzulli/sglang-rtxpro6000.git"
MODEL_FILES = {
    f"layer-{layer:05d}-experts-{start:04d}-{start+127:04d}.safetensors":
        (354098208 if start == 0 else 354099528) + (1536 if layer >= 10 else 0)
    for layer in range(48) for start in (0, 128, 256, 384)
}
MODEL_FILES.update({
    "model-bf16-00001.safetensors": 1273111264,
    "model-bf16-00010.safetensors": 323563728,
    "model-bf16-00011.safetensors": 10727387912,
    "model-bf16-00012.safetensors": 3683689888,
    **{f"model-plefp8-{part:05d}.safetensors": size for part, size in enumerate([
        5200027120, 5200027120, 5200027120, 5200027104, 5200027112,
        5200027112, 5200027112, 5200027112, 5200027112, 4400023074,
    ])},
})
MODEL_SPEC = {
    "id": "qwen38_flash_next_modelopt_sglang",
    "name": "OrcaRouter Flash-Next ModelOpt NVFP4 · SGLang/Penny Royal",
    "repo_id": "jpezzulli/OrcaRouter-Qwen3.8-Flash-Next-Uncensored-ModelOpt-NVFP4",
    "revision": "f24d2b68ff2814f24455ae86717be276619b5664",
    "backend": "sglang", "modality": "llm_vlm", "gated": False, "metadata_first": True,
    "category": "实验 · Penny Royal · SM120 96GB · PLE FP8→CPU · MTP",
    "approx_size_gb": 125.91, "file_sizes": MODEL_FILES,
    "files": [(name, "FP8 PLE 查表分片" if "plefp8" in name else ("BF16/视觉/MTP 分片" if "bf16" in name else "ModelOpt NVFP4 专家分片")) for name in MODEL_FILES],
}
PROCESSES = set()


def runtime_root():
    return Path(os.getcwd()) / ".easycolab-pennyroyal"


def runtime_python():
    path = os.environ.get("EASYCOLAB_SGLANG_PYTHON", "").strip() or str(runtime_root() / ".venv/bin/python")
    if ".easycolab-vllm-venv" in Path(path).parts or ".easycolab-vllm-venv" in Path(path).resolve().parts:
        raise RuntimeError("SGLang 不能使用现有 vLLM 环境；请使用独立 Penny Royal Python。")
    return path


def runtime_environment(python_path, offline=False):
    environment = os.environ.copy()
    for key in ("HF_TOKEN", "HUGGING_FACE_HUB_TOKEN", "CLOUDFLARE_TUNNEL_TOKEN", "TUNNEL_TOKEN", "PYTHONPATH", "PYTHONHOME"):
        environment.pop(key, None)
    environment["PATH"] = str(Path(python_path).parent) + os.pathsep + str(Path.home() / ".cargo/bin") + os.pathsep + environment.get("PATH", "")
    cuda_home = os.environ.get("EASYCOLAB_SGLANG_CUDA_HOME", "") or os.environ.get("CUDA_HOME", "")
    if not cuda_home:
        cuda_home = "/usr/local/cuda-13.3" if Path("/usr/local/cuda-13.3/bin/nvcc").is_file() else "/usr/local/cuda"
    environment.update(CUDA_HOME=cuda_home, CUDACXX=cuda_home + "/bin/nvcc", MAX_JOBS="4", CMAKE_BUILD_PARALLEL_LEVEL="4", CARGO_BUILD_JOBS="4",
                       FLASHINFER_NINJA_JOBS="4", FLASHINFER_NVCC_THREADS="1", TORCH_CUDA_ARCH_LIST="12.0", FLASHINFER_CUDA_ARCH_LIST="12.0f",
                       SGLANG_FORWARD_UNKNOWN_TOOLS="false", NUMPY_MADVISE_HUGEPAGE="0", SGLANG_MM_PREPROCESS_DEVICE="cpu",
                       SGLANG_OPT_MAMBA_SKIP_DECODE_LOCK="1", TOKENIZERS_PARALLELISM="false", OMP_NUM_THREADS="4",
                       PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True")
    environment["PATH"] += os.pathsep + cuda_home + "/bin"
    environment["CC"] = os.environ.get("EASYCOLAB_SGLANG_CC", shutil.which("gcc-15") or shutil.which("gcc-14") or "/usr/bin/gcc")
    environment["CXX"] = os.environ.get("EASYCOLAB_SGLANG_CXX", shutil.which("g++-15") or shutil.which("g++-14") or "/usr/bin/g++")
    environment["CUDAHOSTCXX"] = environment["CXX"]
    cache = str(runtime_root() / "cache")
    environment.update(TORCHINDUCTOR_CACHE_DIR=cache + "/inductor", TRITON_CACHE_DIR=cache + "/triton",
                       FLASHINFER_WORKSPACE_BASE=cache + "/flashinfer", SGLANG_JIT_CACHE_DIR=cache + "/sglang", TILELANG_CACHE_DIR=cache + "/tilelang")
    if offline:
        environment.update(HF_HUB_OFFLINE="1", TRANSFORMERS_OFFLINE="1")
    return environment


def validate_devices(devices):
    if not devices or devices[0][:2] != (12, 0) or devices[0][2] < 90:
        raise RuntimeError("该 Penny Royal 实验配置需要单张 RTX PRO 6000 SM120 96GB，不会改用其他后端。")


def validate_hardware(torch):
    devices = [(*torch.cuda.get_device_capability(index), torch.cuda.get_device_properties(index).total_memory / 1024**3)
               for index in range(torch.cuda.device_count())]
    validate_devices(devices)


def validate_context(context_length):
    if not 4096 <= context_length <= 32768:
        raise ValueError("SGLang 实验模式先验证 4K–32K 上下文；暂不启用 524K/HiCache/DFlash2。")


def validate_memory(available_gib):
    if available_gib < 72:
        raise RuntimeError(f"当前可用 RAM {available_gib:.1f} GiB；FP8 PLE 约 47.7 GiB，SGLang 至少预留 72 GiB 可用 RAM。")


def preflight():
    environment = runtime_environment(runtime_python())
    problems = []
    if not sys.platform.startswith("linux"):
        problems.append("Penny Royal 必须在 Linux GPU 主机运行，不在桌面本机执行。")
    for executable in (environment["CC"], environment["CXX"], "cargo", "git"):
        if not shutil.which(executable, path=environment["PATH"]):
            problems.append("缺少构建工具: " + executable)
    try:
        compiler = subprocess.run([environment["CXX"], "-E", "-x", "c++", "-"],
                                  input="#if defined(__has_feature) && __has_feature(address_sanitizer)\n#endif\n",
                                  capture_output=True, text=True, timeout=10)
        if compiler.returncode:
            problems.append("C++ 编译器不支持上游所需宏，请安装 GCC/G++ 14 或 15，并设置 EASYCOLAB_SGLANG_CC/CXX。")
    except (OSError, subprocess.TimeoutExpired):
        problems.append("无法运行 C++ 编译器预检，请配置 GCC/G++ 14 或 15。")
    try:
        result = subprocess.run([environment["CUDACXX"], "--version"], capture_output=True, text=True, timeout=10)
        version = re.search(r"release (\d+)\.(\d+)", result.stdout)
        if not version or tuple(map(int, version.groups())) < (13, 3):
            problems.append("Penny Royal 固定版本需要 CUDA 13.3+ 编译工具链；可设置 EASYCOLAB_SGLANG_CUDA_HOME，不会自动升级宿主驱动。")
    except (OSError, subprocess.TimeoutExpired):
        problems.append("缺少 CUDA 13.3 nvcc；请设置 EASYCOLAB_SGLANG_CUDA_HOME。")
    return {"ok": not problems, "problems": problems, "python": runtime_python(), "revision": PENNY_REVISION}


def prepare_runtime(report):
    check = preflight()
    if not check["ok"]:
        raise RuntimeError("\n".join(check["problems"]))
    root = runtime_root()
    source = root / "source"
    python = runtime_python()
    environment = runtime_environment(python)
    if os.environ.get("EASYCOLAB_SGLANG_PYTHON", "").strip():
        raise RuntimeError("自定义 SGLang 环境由用户管理，不自动安装或覆盖。")
    root.mkdir(parents=True, exist_ok=True)
    if shutil.disk_usage(root).free < 25 * 1024**3:
        raise RuntimeError("Penny Royal 环境安装至少预留 25 GiB 本地空间（不含 126 GiB 模型缓存）。")
    report("正在准备独立 Penny Royal 3.1.6 源码及 Python 环境，不修改 vLLM...")
    if not (source / ".git").is_dir():
        _run_runtime_command(["git", "clone", "--filter=blob:none", "--no-checkout", PENNY_REPOSITORY, str(source)], environment, 300, "获取 Penny Royal")
    else:
        dirty = subprocess.run(["git", "-C", str(source), "status", "--porcelain", "--untracked-files=no"], capture_output=True, text=True, timeout=20)
        if dirty.returncode or dirty.stdout.strip():
            raise RuntimeError("Penny Royal 源码有本地修改，停止自动安装以避免覆盖。")
    _run_runtime_command(["git", "-C", str(source), "checkout", "--detach", PENNY_REVISION], environment, 120, "固定 Penny Royal 源码")
    base_python = shutil.which("python3.12") or sys.executable
    _run_runtime_command([base_python, "-m", "venv", "--without-pip", str(Path(python).parent.parent)], environment, 120, "创建 SGLang 独立环境")
    _run_runtime_command([sys.executable, "-m", "pip", "--python", python, "install", "--no-cache-dir", "pip", "uv", "setuptools>=61", "setuptools-rust>=1.10", "setuptools-scm>=8", "wheel", "wheel-stub==0.5.0", "build", "ninja"], environment, 600, "安装 SGLang 构建依赖")
    report("正在安装固定源码的 SGLang 依赖；首次构建可能较长...")
    _run_runtime_command([python, "-m", "uv", "pip", "install", "--python", python, "--prerelease=allow", "--index-strategy", "unsafe-best-match", "--extra-index-url", "https://docs.sglang.ai/whl/cu130/", "--no-build-isolation", "-e", str(source / "python")], environment, 2400, "安装 Penny Royal")
    _run_runtime_command([python, str(source / "scripts/pennyroyal/flashinfer/install.py")], environment, 2400, "构建 Penny Royal SM120 内核")
    (root / ".ready").write_text(PENNY_REVISION)


def ensure_runtime(report):
    python = runtime_python()
    marker = runtime_root() / ".ready"
    if not Path(python).is_file() or (not os.environ.get("EASYCOLAB_SGLANG_PYTHON") and (not marker.is_file() or marker.read_text() != PENNY_REVISION)):
        check = preflight()
        if not check["ok"]:
            raise RuntimeError("SGLang/Penny Royal 环境未就绪：" + " ".join(check["problems"]))
        prepare_runtime(report)
    environment = runtime_environment(python)
    result = subprocess.run([python, "-c", "from sglang.srt.models.qwen4_exp import Qwen4ExpForConditionalGeneration; from sglang.srt.server_args import prepare_server_args"],
                            env=environment, capture_output=True, text=True, timeout=120)
    if result.returncode:
        raise RuntimeError("SGLang 架构校验失败，未切换 vLLM：" + redact_diagnostic(result.stderr[-2500:]))
    return python


def validate_checkpoint(directory):
    config = json.loads((Path(directory) / "config.json").read_text())
    quant = config.get("quantization_config", {})
    if config.get("model_type") != "qwen4_exp" or quant.get("quant_method") != "modelopt" or quant.get("quant_algo") != "NVFP4":
        raise RuntimeError("新模型需要 jpezzulli ModelOpt NVFP4 权重，不能使用旧 compressed-tensors 文件。")
    manifest = json.loads((Path(directory) / ".easycolab-metadata.json").read_text())
    if manifest.get("repo_id") != MODEL_SPEC["repo_id"] or manifest.get("revision") != MODEL_SPEC["revision"]:
        raise RuntimeError("ModelOpt 模型版本不匹配，请先校验固定版本权重。")


def stage_checkpoint(directory, report):
    from easycolab_transfer import find_rclone_mount

    source = Path(directory)
    mount = find_rclone_mount(directory)
    if not mount:
        return directory
    destination = Path(os.getcwd()) / "models" / MODEL_SPEC["repo_id"]
    destination.mkdir(parents=True, exist_ok=True)
    if destination.is_symlink() or find_rclone_mount(str(destination.resolve())):
        raise RuntimeError("SGLang 本地缓存目录不能指向云盘或软链接。")
    manifest = json.loads((source / ".easycolab-metadata.json").read_text())
    metadata = manifest["files"]
    for name in (*MODEL_FILES, *metadata, ".easycolab-metadata.json"):
        target = destination / name
        if os.path.isabs(name) or os.path.normpath(name) != name or name.startswith("..") or target.is_symlink() or not target.resolve().is_relative_to(destination.resolve()):
            raise RuntimeError("SGLang 缓存路径无效，未写入文件。")
    missing = sum(size for name, size in MODEL_FILES.items() if not (destination/name).is_file() or (destination/name).stat().st_size != size)
    if shutil.disk_usage(destination).free < missing + 22 * 1024**3:
        raise RuntimeError(f"SGLang 缓存还需 {missing/1024**3:.1f} GiB 加 22 GiB 余量；不会删除旧 vLLM 权重，请释放空间或使用新实例。")
    if missing:
        report(f"正在从 Drive 预热独立 ModelOpt 权重至 SSD（{missing/1024**3:.1f} GiB），旧 vLLM 文件保持不变...")
        _run_runtime_command(["rclone", "copy", mount["remote"], str(destination), "--include", "/*.safetensors", "--size-only", "--transfers", "4", "--multi-thread-streams", "4", "--stats", "5s", "--stats-one-line", "--stats-log-level", "NOTICE"],
                             runtime_environment(runtime_python()), 3600, "预热 ModelOpt 权重")
    for name, size in MODEL_FILES.items():
        if not (destination/name).is_file() or (destination/name).stat().st_size != size:
            raise RuntimeError("SGLang 本地权重大小校验失败，未启动。")
    for name in (*metadata, ".easycolab-metadata.json"):
        target = destination/name
        target.parent.mkdir(parents=True, exist_ok=True)
        temporary = target.with_name(target.name + ".staging")
        shutil.copyfile(source/name, temporary)
        os.replace(temporary, target)
    return str(destination)


def build_command(python, directory, port, context_length):
    validate_context(context_length)
    return [python, "-m", "sglang.launch_server", "--model-path", directory, "--served-model-name", MODEL_SPEC["repo_id"],
            "--host", "127.0.0.1", "--port", str(port), "--tp", "1", "--dtype", "bfloat16", "--quantization", "modelopt_fp4",
            "--ple-offload-embedding", "--fp4-gemm-backend", "flashinfer_cutlass", "--moe-runner-backend", "flashinfer_cutlass",
            "--context-length", str(context_length), "--max-running-requests", "1", "--chunked-prefill-size", "4096",
            "--mem-fraction-static", "0.93", "--kv-cache-dtype", "auto", "--page-size", "64", "--mamba-track-interval", "64",
            "--mamba-ssm-dtype", "bfloat16", "--mamba-radix-cache-strategy", "extra_buffer_lazy", "--max-mamba-cache-size", "5",
            "--speculative-algorithm", "NEXTN", "--speculative-num-steps", "3", "--speculative-eagle-topk", "1", "--speculative-num-draft-tokens", "4",
            "--cuda-graph-max-bs", "1", "--reasoning-parser", "qwen3", "--tool-call-parser", "qwen3_coder", "--trust-remote-code", "--watchdog-timeout", "1800"]


def start_server(directory, context_length, report):
    validate_context(context_length)
    validate_checkpoint(directory)
    python = ensure_runtime(report)
    directory = stage_checkpoint(directory, report)
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        port = listener.getsockname()[1]
    report("正在启动独立 SGLang/Penny Royal：TP1、FP8 PLE→CPU、NEXTN MTP、CUDA Graph；首次加载与内核编译可能耗时十余分钟。")
    started_at = time.monotonic()
    process = subprocess.Popen(build_command(python, directory, port, context_length), env=runtime_environment(python, offline=True),
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace", bufsize=1, start_new_session=True)
    PROCESSES.add(process)
    logs = deque(maxlen=40)

    def drain():
        try:
            for line in process.stdout:
                clean = redact_diagnostic(line.rstrip())[-1800:]
                if clean:
                    logs.append(clean)
                    print("[SGLang] " + clean, flush=True)
        finally:
            process.stdout.close()

    thread = threading.Thread(target=drain, daemon=True)
    thread.start()
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    base = f"http://127.0.0.1:{port}"
    try:
        deadline = started_at + 1800
        while process.poll() is None and time.monotonic() < deadline:
            try:
                with opener.open(base + "/health", timeout=2) as response:
                    if response.status == 200:
                        report(f"SGLang/Penny Royal 健康检查通过，加载与预热耗时 {time.monotonic() - started_at:.1f} 秒。")
                        return {"backend": "sglang", "model_id": MODEL_SPEC["id"], "served_model": MODEL_SPEC["repo_id"], "base_url": base,
                                "server_proc": process, "context_length": context_length, "mode_label": f"Penny Royal ModelOpt NVFP4 · MTP · {context_length//1024}K"}
            except OSError:
                pass
            time.sleep(1)
        thread.join(timeout=2)
        raise RuntimeError("SGLang 启动失败/超时，不回退 vLLM。\n" + "\n".join(logs)[-3500:])
    except BaseException:
        stop_server(process)
        PROCESSES.discard(process)
        raise


def cleanup():
    for process in list(PROCESSES):
        if process.poll() is None:
            stop_server(process)
        PROCESSES.discard(process)


atexit.register(cleanup)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("preflight", "prepare"))
    arguments = parser.parse_args()
    if arguments.command == "preflight":
        print(json.dumps(preflight(), ensure_ascii=False))
    else:
        prepare_runtime(print)
