# EasyColab

**简体中文** | [English](./README_EN.md)

**EasyColab** 是一款专为 **macOS 与 Windows** 原生打造的 Google Colab 云端大显存多模态 AI 创作工作台（macOS SwiftUI 原生客户端 + Windows PySide6/Qt6 桌面客户端 + 云端多模型加速引擎）。

默认适配 **Google Colab G4（NVIDIA RTX PRO 6000 Blackwell · `96 GB` 显存 + `176 GB` 系统内存）** 以及 `H100 / A100 / L4` 实例，支持免开网页一键唤醒部署、Google Drive 云盘权重永久复用、多模型显存共驻、实时算力折线图监控、中英文双语界面一键切换与闲置自动释放省额度。

![EasyColab 工作台界面预览](./shot.png)

---

## 核心特性

- **双平台桌面级创作体验 + 中英文双语切换 + 新手交互引导（macOS & Windows 1:1 全功能对齐）**
  - **macOS 端**采用纯原生 SwiftUI + AppKit 构建，**Windows 端**采用 PySide6 (Qt6 + FFmpeg 多媒体管线) 构建并适配 Windows 11 沉浸式深浅色标题栏与高分屏缩放；首次启动均自带 **4 步交互式新手引导**，零配置自动初始化连接组件。
  - 支持 **中英文（简体中文 / English）界面实时一键切换**（默认显示中文），状态与偏好自动记忆，无需重启应用。
  - 实时绘制云端 **GPU 显存 / 系统内存 / 磁盘空间** 平滑曲线走势图（支持分项与同屏叠加模式），同步显示官方真实剩余 **CU 计算单元** 与每小时消耗速率。
  - 内置 **30 分钟闲置自动休眠看门狗** 与一键「断开并释放实例」，杜绝忘记关机空耗算力额度。

- **四大旗舰开源多模态引擎开箱即用**
  1. **`MiniMax-H3 (BF16 原生满血)` · 4～15 秒电影级有声视频**
     - 支持文生有声视频、首帧图生视频、首尾帧过渡控镜，原生输出 `24 FPS` 画面 + `32 kHz` 立体声音轨。
     - **G4 176GB 双主干内存热备加速**：自动将 `32B 文本编码器` 与 `33B DiT 主干` 常驻高速 DDR5 内存，同提示词连抽 `0 ms` 瞬回，修改新提示词整块 PCIe 换入解析仅需约 `8～12 秒`。
  2. **`ComfyUI 节点工作台` · 云盘持久化 + 4 套零基础预置工作流包**
     - 一键部署 ComfyUI + Manager 并开通免费 Cloudflare HTTPS 加密隧道，所有 `custom_nodes`、`models` 与 `workflows` 自动软链/同步至 Google Drive。
     - 内置 **万相 Wan2.2 14B**、**MiniMax-H3 Turbo**、**LTX-2.3 (22B)**、**混元 HunyuanVideo 1.5** 四套「一键配齐模型 + 节点指引」的图生视频与首尾帧运镜工作流。
  3. **`Qwen3.8-27B (UD-Q4_K_M + MTP 投机解码 / BF16)` · 100 tok/s 视觉对话与双协议网关**
     - 支持最高 `256K` 上下文、长思维链推理、多模态看图反推提示词。
     - 内置兼容 **OpenAI (`/v1/chat/completions`)** 与 **Anthropic (`/v1/messages`)** 的公网 API 网关（支持 Bearer / `x-api-key` 鉴权），可直接接入 **Claude Code**、**Cursor** 等开发工具。
     - 可选 [**DeepSeek-V4-Pro-Qwen3.5-9B-UNCENSORED-heretic**](https://huggingface.co/xtools-at/DeepSeek-V4-Pro-Qwen3.5-9B-UNCENSORED-heretic)：基于 Qwen3.5-9B 的蒸馏推理模型，复用 BF16 对话、视觉与双协议网关流程。下载约 `18 GiB`（4 个主分片 + 索引必需的 MTP 权重，不启用 MTP 投机解码），加载前至少预留约 `20 GiB` 可用显存，长上下文另需额外显存；API 的 `model` 使用完整仓库 ID。
     - 可选 **Qwen3.8-Flash-Next-Uncensored-NVFP4**：独立 vLLM 后端，针对单张 RTX PRO 6000 Blackwell 96GB 使用 PLE CPU 卸载；不是 27B 模型，需 HF 授权，完整下载约 `170.9 GiB`，详见下方单卡部署说明。
  4. **`Qwen-Image-2.1` & `Z-Image-Turbo` · 2K 海报生图与多图指令修图**
     - 支持高质感中英文排版直出、双图自然语言指令修图与 8 步极速出图；所有生成的 MP4 / PNG 自动回传至本地目录（macOS: `~/Movies/EasyColab`，Windows: `%USERPROFILE%\Videos\EasyColab`）。

---

## 快速开始

### 新增实验后端：ModelOpt NVFP4 / SGLang · Penny Royal

模型列表中新增 **OrcaRouter Flash-Next ModelOpt · Penny Royal**，与原来的 `orcarouter/...-NVFP4` vLLM 模型并存，不修改旧权重、旧 vLLM 环境或启动参数。

- 仓库：[`jpezzulli/OrcaRouter-Qwen3.8-Flash-Next-Uncensored-ModelOpt-NVFP4`](https://huggingface.co/jpezzulli/OrcaRouter-Qwen3.8-Flash-Next-Uncensored-ModelOpt-NVFP4)，固定 revision `f24d2b68ff2814f24455ae86717be276619b5664`。206 个权重文件、约 **125.91 GiB**，FP8 PLE 表约 47.7 GiB；这是同源原模的另一套量化，不是旧 NVFP4 的重命名。
- 后端：独立 Penny Royal 3.1.6，固定源码 `202f266be2d46453e098792fa39057e859fb8095`，目录 `.easycolab-pennyroyal`。新 API model ID 使用完整的新仓库名，内部 ID 为 `qwen38_flash_next_modelopt_sglang`，不会静默回退到 vLLM。
- 初始实验配置：单张 SM120 RTX PRO 6000 96GB、至少 72 GiB 可用 RAM、4K–32K 上下文、单并发、ModelOpt NVFP4、FP8 PLE→CPU、NEXTN MTP 3 步/4 token、小规模 CUDA Graph、BF16 KV。Penny Royal 会对适用的 dense projection、HC 和 lm_head 在线转为 rowwise FP8，并非所有 BF16 分片都以 BF16 执行。暂不启用 524K、FR-Spec、HiCache/NIXL 或 DFlash2，不能套用完整 Penny Royal 配方的性能数字。
- 下载、Drive 字节进度与远端确认复用现有流程，但使用独立 `models/jpezzulli/...` 目录。加载需约 126 GiB SSD 缓存及 22 GiB 余量，另给构建环境留至少 25 GiB；保留旧 171 GiB 缓存的 Colab 实例通常放不下两套，不会自动删除旧模型。
- 源码构建需要 Linux、CUDA 13.3 编译工具链、兼容 C/C++ 编译器、Rust/Cargo、Python 3.12（优先）及 Git。使用 `EASYCOLAB_SGLANG_CUDA_HOME`、`EASYCOLAB_SGLANG_CC`、`EASYCOLAB_SGLANG_CXX` 指定工具链。安装工具包不等于升级 Colab 宿主驱动；仅下述组合经过实机验证。
- 可在 GPU 上先运行 `python easycolab_sglang.py preflight`，再运行 `python easycolab_sglang.py prepare`；或使用 `EASYCOLAB_SGLANG_PYTHON=/path/to/pennyroyal/.venv/bin/python` 接入已准备的独立环境。**不能指向 `.easycolab-vllm-venv`**。环境预检/安装失败不会卸载正在使用的旧模型；正式切换加载时两套大模型不能在同一张卡上同时驻留。

Colab Ubuntu 24.04 的系统 GCC 13 不支持本版本 FlashInfer 补丁中的 `__has_feature` 宏，已实测会导致编译失败。新实例需要先准备系统工具链；应用不会自动安装系统包或升级驱动。以下在 **Colab GPU 终端**执行（需要 root 及已有 NVIDIA CUDA apt 软件源，不要在 Mac/Windows 本机执行）：

```bash
apt-get update -qq
apt-get install -y --no-install-recommends cuda-toolkit-13-3 gcc-14 g++-14 build-essential pkg-config libssl-dev protobuf-compiler python3.12-dev ninja-build
curl --fail --location --proto '=https' --tlsv1.2 https://sh.rustup.rs -o /tmp/easycolab-rustup.sh
sh /tmp/easycolab-rustup.sh -y --profile minimal --default-toolchain stable
export PATH="$HOME/.cargo/bin:$PATH"
export EASYCOLAB_SGLANG_CUDA_HOME=/usr/local/cuda-13.3
export EASYCOLAB_SGLANG_CC=/usr/bin/gcc-14
export EASYCOLAB_SGLANG_CXX=/usr/bin/g++-14
python easycolab_sglang.py preflight
python easycolab_sglang.py prepare
```

`wheel-stub==0.5.0` 已纳入独立构建依赖，供 NVIDIA `cuda-tile` 预发布包查找官方 wheel。不要跳过上游 SM120 内核构建或通过删除量化配置绕过错误。

**2026-11-09 实机冒烟验证：**Colab 单张 RTX PRO 6000 96GB、驱动 580.82.07、CUDA Toolkit 13.3.1、GCC 14、Python 3.12，成功构建 SM120 fused MoE 内核并启动 4K 配置。206 个权重分片从本地 SSD 读取约 7 分 53 秒，完整主模型加载阶段约 500 秒，MTP 加载另用约 206 秒；首次启动至两条测试完成约 795 秒（含在线转换、JIT 和预热，不含依赖安装）。Target verify、draft decode/extend CUDA Graph 捕获成功，prefill graph 由上游自动禁用。健康检查返回 200，英文请求返回 `OK`，中文请求返回完整且相关的一句话。这里只验证了基础推理，不构成与 vLLM 的公平性能对比；32K、多模态、工具调用和长时间稳定性仍需实机验证。模型文件同步到 Drive 后经 rclone 校验 219 个文件一致；编译环境和 SSD 缓存仍随实例释放而丢失。

依据：[Penny Royal 固定版本构建说明](https://github.com/jpezzulli/sglang-rtxpro6000/blob/pennyroyal-v3.1.6/BUILD.md)、[模型卡](https://huggingface.co/jpezzulli/OrcaRouter-Qwen3.8-Flash-Next-Uncensored-ModelOpt-NVFP4)、[SGLang 单卡部署配方](https://docs.sglang.io/cookbook/autoregressive/Qwen/Qwen3.8-Flash-Next)。本实验集成的实测结果与限制应单独记录，不把模型被列出等同于已经验证稳定性或速度。

### Qwen3.8-Flash-Next NVFP4：单卡 G4 96GB

此模型不能全量塞进 96GB 显存。固定仓库版本 `9c6f1345b523a9d9d70b41542a63b39e3c9b7ca6` 有 17 个主分片及 MTP 文件，合计约 **170.9 GiB / 183.5 GB**；其中第二个分片约 **95.4 GiB**，对应巨大的 BF16 PLE n-gram 表。不加载 MTP、将 PLE 放在 CPU 后，其余主权重约 **70.7 GiB**，仍需为计算、视觉编码器与 KV cache 留显存。

1. 在 [模型页](https://huggingface.co/orcarouter/Qwen3.8-Flash-Next-Uncensored-NVFP4) 登录并接受访问条款，在 EasyColab 输入有该仓库读取权限的 **HF Token**（不是 Cloudflare Token）。遵守模型的使用条款与研究用途说明。
2. 使用 **RTX PRO 6000 Blackwell 96GB + 高系统内存 G4**。代码检查 Blackwell、至少 90 GiB 总显存、90% 空闲显存，以及卸载现有模型后至少 **112 GiB 可用系统内存**（不是总内存）。不满足会报出原因，不会偷偷改用 BF16。H100/A100/L4/T4 不能使用此 NVFP4 方案。
3. Google Drive 至少预留约 **180 GiB**；通过模型列表下载，权重与配置仍完整保存在 `models/orcarouter/Qwen3.8-Flash-Next-Uncensored-NVFP4/`，以后挂载复用，不重复从 HF 下载。加载时会重新把 PLE 读入 CPU RAM、其他权重读入 GPU，不等于零加载时间。这里不把 95 GiB PLE 再复制到 `/dev/shm`，也不使用一次读取整个巨大文件的 eager 策略；Drive 随机读取仍可能较慢。
4. 先设置 **4K–32K 上下文**，点击「加载到显存」。首次按需创建 `.easycolab-vllm-venv`，安装 `vllm==0.33.0`、`transformers==5.20.1`（符合 vLLM 的 `>=5.16.1,<5.21.0` 依赖限制），不升级主服务的 PyTorch。需要 Linux、Python 3.11+、兼容该 vLLM CUDA wheel 的 NVIDIA 驱动及本地安装空间。可在云端启动服务前用 `EASYCOLAB_VLLM_PYTHON=/path/to/venv/bin/python` 指定已准备的兼容独立环境。
5. 单卡配置为 TP1、`--engram-config '{"cpu_offload":true}'`、`--safetensors-load-strategy lazy`、单并发、2048 token 分块预填充、关闭 FlashInfer autotune 和 CUDA Graph，**不默认启用 MTP**，保留原始混合精度与 BF16 KV。保守起步配置最多两张图片、不接收视频；图像和更长上下文会增加内存压力。先确认稳定，再单独评估 MTP/长上下文，不能套用文章其他权重版本的速度数字。

API `model` 使用 `orcarouter/Qwen3.8-Flash-Next-Uncensored-NVFP4`，复用桌面对话、图片、OpenAI/Anthropic 网关与工具调用。思考模式默认 `medium`，可用 `chat_template_kwargs.enable_thinking=false` 关闭。若显存不足，先降到 4K/8K 并关闭其他 GPU 任务；若 RAM 不足，仅缩短上下文无法消除约 95 GiB PLE 的常驻内存需求。启动失败会清理 vLLM 子进程并保留诊断日志。

独立环境采用 `venv --without-pip` 与主解释器的 [`pip --python`](https://pip.pypa.io/en/stable/topics/python-option/) 引导（主环境需 pip ≥22.3），兼容 Colab 缺少 `ensurepip` 的 Python，无需安装会升级共享 Python 的系统包。pip、vLLM 和 Transformers 仅安装到独立环境；安装输出实时同步到客户端日志，失败显示退出码与脱敏日志尾部。已有权重不会重新下载。

**Qwen4 混合精度兼容修复：** vLLM 0.33.0 原版把 FP8 Q/K/V 与 BF16 QSA 索引器合并，导致 `Found different quantization schemes for the shards`。受管独立环境会移植上游的条件融合逻辑：从静态 QKV 映射移出索引器，只有量化方法兼容时才融合。保留原 FP8/NVFP4/BF16 权重，不删除量化配置、不重新下载权重。修复限定 vLLM 0.33.0，并校验源码、备份原文件；自定义 `EASYCOLAB_VLLM_PYTHON` 不会被自动修改，应自行安装包含相应修复的版本。启动诊断保留原始异常，不只显示后续的 `Engine core initialization failed`。

**FlashInfer 内核：** 受管环境固定 `flashinfer-python==0.7.2.post1`，从 FlashInfer 官方 wheel 源安装同版本 `flashinfer-cubin`，并通过 `python -m flashinfer install-jit-cache-wheel --mode minimal` 安装匹配 PyTorch CUDA 版本及当前 GPU 的 JIT 缓存；RTX PRO 6000 对应 `cu130/sm120f`，不下载所有架构。安装过程保留超时和实时日志。启动时将独立环境的 `bin` 放到 PATH 首位，使其 `ninja` 可见，并从 `nvcc` 检测 `CUDA_HOME`。预编译包不涵盖所有 JIT 特化，首次加载仍可能编译。不会直接启用高显存开销的 autotune/CUDA Graph，也不会用“隐藏警告”代替依赖修复。[FlashInfer 官方安装说明](https://docs.flashinfer.ai/installation.html)、[上游条件融合实现](https://github.com/vllm-project/vllm/blob/main/vllm/models/qwen4_exp/nvidia/qsa.py)。

**vLLM 本地 SSD 预热：** `lazy` safetensors 在 rclone FUSE 上随机读取可能极慢（本次实测约 4 MiB/s），而改为 `eager` 会与 95 GiB PLE 常驻内存叠加。现在针对 rclone 挂载先以 `rclone copy` 并行复制到实例的 `models/<repo>`，确认大小并更新配置，再从本地文件 mmap 加载。首次需约 171 GiB SSD 空间及 22 GiB 安全余量；已有完整本地分片跳过复制，Drive 原件不变。预热日志每 5 秒显示进度，空间不足直接提示，不自动删文件或退回慢速路径。实例释放后 SSD 缓存消失，但云盘副本仍可复用。

**实机验证（2026-11-09）：** Colab RTX PRO 6000 Blackwell Server Edition（94.97 GiB 显存）、4K 上下文、单卡 TP1、PLE CPU 卸载，完整加载 18 个权重文件后健康检查通过，OpenAI Chat Completions 短文本请求返回 `OK`（18 输入 token、2 输出 token）。日志显示模型加载使用约 71.02 GiB 显存，此数值不含所有 KV/运行时峰值。FlashInfer GDN prefill 和采样内核启用，MoE 自动选择 Marlin 兼容路径。尚未验证 32K 长上下文、真实图片请求、并发稳定性或正式吞吐性能。

依据：[文章](https://www.orcarouter.ai/blog/qwen3-8-flash-next-uncensored-nvfp4)、[vLLM 0.33.0 EngramConfig](https://github.com/vllm-project/vllm/blob/v0.33.0/vllm/config/engram.py)、[Qwen4 PLE pinned-host 实现](https://github.com/vllm-project/vllm/blob/v0.33.0/vllm/models/qwen4_exp/common/ngram_embedding.py)、[权重加载策略](https://github.com/vllm-project/vllm/blob/v0.33.0/vllm/config/load.py)。这是基于上游实现的单卡集成方案，本地检查不能替代该 gated 权重在实际 Colab GPU 上的完整加载与推理验证。

### 系统要求
- **操作系统**：
  - **macOS**：macOS 13.0 (Ventura) 或更高版本（推荐 Apple Silicon / macOS Sonoma & Sequoia）
  - **Windows**：Windows 10 (1903+) 或 Windows 11 64 位 (x64)
- **云端账号**：开通了 **Google Colab Pro / Pro+ / Google AI Ultra**（拥有可用 CU 计算单元）的 Google 账号；免费版用户请使用下方「Google Colab 官方网页端运行 `.ipynb`」。

---

### macOS 客户端

#### 方式一：本地一行命令编译运行（推荐，无 Gatekeeper 拦截）
只需系统装有 Xcode Command Line Tools（若未安装可执行 `xcode-select --install`）：

```bash
git clone https://github.com/<your-username>/EasyColab.git
cd EasyColab
bash macos_app/build_macos_app.sh
open EasyColab.app
```

> 编译脚本会自动将 `app.py`、`colab_bridge.py`、`easycolab_tunnel.py`、`easycolab_vllm.py`、`EasyColab_Server.ipynb` 打包进 `EasyColab.app/Contents/Resources/`。你可以将生成的 `EasyColab.app` 直接拖入 `/Applications` 独立使用；首次点击「绑定」时，应用会在 `~/Library/Application Support/EasyColab/venv` 自动创建隔离 Python 环境并安装连接组件。

#### 方式二：从 GitHub Releases 下载预编译 `.app`
若下载的是未经过 Apple Developer ID 公证的预编译 `.app`，首次打开若遇到 macOS 提示 *“无法验证开发者 / 已损坏”*，请在终端执行一次解除隔离命令：

```bash
xattr -cr /Applications/EasyColab.app
```

---

### Windows 客户端

#### 方式一：下载免安装绿色版 `.zip`（零 Python 依赖，推荐）
1. 从 GitHub Releases（或仓库 **Actions -> Build EasyColab Windows App** 构建产物）下载 `EasyColab-Windows-x64.zip`。
2. 解压到任意目录后，直接双击运行 `EasyColab\EasyColab.exe` 即可使用（已内置 Python 运行时、Qt6 界面库、FFmpeg 音视频解码器与 `colab_bridge` 云端唤醒组件，无需在电脑上安装 Python）。
3. 如遇 Windows SmartScreen 提示 *“Windows 已保护你的电脑”*，点击 **「更多信息」 -> 「仍要运行」** 即可。

#### 方式二：Windows 本地一键打包独立 `.exe`
若本机已安装 Python 3.10～3.13（64 位），在仓库根目录可直接一键创建隔离虚拟环境并编译生成 `dist\EasyColab\EasyColab.exe` 与 `EasyColab-Windows-x64.zip`：

```bat
REM 双击或在 CMD 中运行：
windows_app\build_windows_app.bat
```

或使用 PowerShell：

```powershell
powershell -ExecutionPolicy Bypass -File .\windows_app\build_windows_app.ps1
```

#### 方式三：在 macOS 上直接交叉打包 Windows 独立 `.exe`
若当前在 macOS 开发机上（已安装 `brew install mingw-w64`），无需 Windows 虚拟机即可直接交叉编译原生 Win32 GUI 启动器并组装完整的 `EasyColab-Windows-x64.zip`：

```bash
python3 windows_app/build_windows_from_mac.py
```

#### 方式四：源码开发模式直接运行（Windows / macOS 通用预览）

```bash
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS:   source .venv/bin/activate
pip install -r windows_app/requirements-windows.txt
python windows_app/easycolab_win.py
```

---

### Google Colab 官方网页端运行（适合 Colab 免费版 / 浏览器用户）
1. 打开 [Google Colab](https://colab.research.google.com/)，上传本仓库根目录下的 `EasyColab_Server.ipynb`（或在客户端引导页点击「导出 / 定位 `.ipynb` 笔记本」）。
2. 在 Colab 菜单栏选择 `代码执行程序 -> 更改运行时类型`，选择 `G4` / `A100` / `L4` GPU 并按顺序运行单元格。
3. 将输出的 `https://xxxx.gradio.live` 链接粘贴至桌面客户端左侧服务地址栏点击「连接」即可。

---

## 模型权重持久化与自定义目录

在笔记本第二步保持 `MOUNT_GOOGLE_DRIVE = True`，按需修改 `EASYCOLAB_MODEL_DIR`，然后完成 Drive 挂载授权并启动服务端。默认模型目录为：

```text
/content/drive/MyDrive/models/<Hugging Face 用户或组织>/<模型仓库>/
```

- 例如可将 `EASYCOLAB_MODEL_DIR` 改为 `/content/drive/MyDrive/AI/models`。目录必须位于挂载的 `MyDrive` 下；修改后需重启服务端。独立启动 `app.py` 时也可设置同名环境变量，优先级高于兼容的 `DIFFSYNTH_MODEL_BASE_PATH`。
- 首次点击「下载权重」会直接写入 Drive，同时保存分词器、Processor、配置和聊天模板等必需文件；仅在文件写入和配置清单校验通过后才显示「完整持久化」。云盘空间不足、写入失败或挂载断开会报错，不会静默改存临时盘。
- 桌面端分别显示「下载/复用」与「Drive 上传」字节进度；总量使用权重真实大小，而不是分片个数。标准 HF 回退下载期间，当前文件的字节数在完成后更新，不将预分配的 `.part` 文件大小冒充已下载量。
- rclone 写缓存不等于云盘数据：下载完后继续等待上传，直接查询 Drive 中所有权重和配置文件的大小、配置清单 MD5，并排除仍待写回的缓存文件，全部通过才设置 `drive_persisted=true`。这不是对所有权重做全量内容哈希。远端不可用、连续查询失败或等待超过两小时会明确报错，完整本地文件保留，可点击「校验权重」重试；此时不要释放实例。
- 新建的桌面端挂载提供仅限 `127.0.0.1`、随机凭据保护的 rclone 监测接口，显示正在传输的字节；凭据仅放在云端 `0600` 临时配置中，不传给客户端或公网。已有挂载不会被重启，只能按远端已完成的文件更新确认进度，超大分片上传期间该数字可能暂时不动。发送 100% 仍需等待远端确认。
- 官方笔记本 `drive.mount()` 没有此 rclone 独立校验通道：文件仍可下载及加载，但界面明确标为「未确认持久化」，不会仅凭挂载路径存在宣称已上云。需独立确认时使用桌面端 rclone 挂载；更新客户端不会自动中断现有下载，请待任务完成后再部署新服务端。
- 下次启动只需重新挂载同一个 Drive，即可复用权重和配置。再次点击「下载权重」也会跳过已有文件；已完成的配置通过 `.easycolab-metadata.json` 清单校验，缺失时自动补齐。运行环境依赖安装仍可能联网。
- 兼容读取旧的 `EasyColab_Models`、`Aevix_Models`、`MiniMax_H3_Models` 和默认 `models` 目录。点击「下载权重」会把旧目录或本地缓存中的文件复制到新目录，不重新下载已有大权重，也不删除旧文件；迁移期间需预留副本空间。
- Drive 是持久化主存储，不是 GPU 显存。每个新实例仍需读取权重到内存/显存，原有加载阶段的 RAM/NVMe 预热机制继续保留。首次下载速度受 Drive 写入速度限制。
- 主动关闭挂载且实例没有其他 Drive 挂载时，文件仅保存在实例临时磁盘，界面会明确提示；释放实例后这些文件会丢失。仅配置 rclone 或启动 ComfyUI 不会将普通模型错误标记为「已持久化」。

### 免网页部署的 Drive 授权

桌面客户端左侧新增 **「连接 Google Drive」**：

1. 本机已有 rclone 授权配置时，自动复用其中的 OAuth Client ID / Secret；点击「连接 / 重新授权」在默认浏览器完成同意即可。无需本机安装或手工配置 rclone。
2. 新机器先点「导入客户端 JSON」，选择你在 Google Cloud 创建并下载的 **桌面应用** OAuth JSON，然后点击连接。JSON 只需导入一次，但不会通过 Colab 登录自动跨机器下载；这里使用的是你自己的 OAuth 客户端，不是 Colab 内置客户端。不要分享该文件或提交 Git。
3. 默认只请求 `drive.file`；要访问非本应用创建的已有目录，明确勾选「访问已有云盘文件（完整 Drive 权限）」。实际登录的账号需位于 Google Auth Platform 测试用户列表，且对应项目已启用 Drive API。
4. 授权使用本机 `127.0.0.1` 临时回调端口、OAuth state 与 PKCE，3 分钟超时；交换 Token 后先验证 Drive API，再原子保存 rclone 配置到 `~/.config/easycolab/drive-rclone.conf`（Windows 为 `%USERPROFILE%\.config\easycolab\drive-rclone.conf`）。失败或取消不主动删除旧授权；自定义 `EASYCOLAB_RCLONE_CONFIG` 路径也生效。
5. 导入的客户端配置保存为 `~/.config/easycolab/drive-oauth-client.json`，这些私密文件在 macOS/Linux 使用 `0600`，Windows 请保留用户目录的私有访问权限。它们包含敏感凭据，不要明文共享到 Drive。Testing 授权仍约 7 天到期，可再次点击连接更新。新授权在下次「唤醒实例并部署」时上传，**不会中断当前服务**。

桌面端「唤醒实例并部署」使用 rclone，而不是笔记本的交互式 `drive.mount()`。现在必须验证 Drive 已挂载才会启动新服务，并设置 `EASYCOLAB_REQUIRE_DRIVE=1`；API 403、授权失效或挂载失败都会停止部署，不再静默使用临时磁盘，也不会因此释放现有实例。

**Google 登录成功不等于 Drive 授权可用。** 如果出现 `SERVICE_DISABLED` / `accessNotConfigured` / `quota project`，说明 OAuth 凭据对应的 Google Cloud 项目未启用 Drive API 或配额配置不可用。反复登录同一个内置客户端通常无法解决；可使用官方笔记本挂载，或为免网页部署配置独立 Drive 授权：

1. 按 [rclone 官方说明](https://rclone.org/drive/#making-your-own-client-id)，在你自己的 Google Cloud 项目启用 **Google Drive API**、配置 OAuth 同意屏幕并创建桌面应用 OAuth Client。必须使用这个项目的客户端重新授权，不是随便在另一个项目启用 API。
2. 在本机安装 rclone，执行以下命令，在交互向导中创建名为 **`easycolab_gdrive`**、类型为 **Google Drive** 的 remote，填入自己的 Client ID / Secret 并完成浏览器授权。不要对该专用配置启用 rclone 配置文件加密；它需要供部署程序读取。

   ```bash
   mkdir -p ~/.config/easycolab
   rclone config --config ~/.config/easycolab/drive-rclone.conf
   chmod 600 ~/.config/easycolab/drive-rclone.conf
   ```

3. 新建专用存储可选择 `drive.file` 权限；它只访问该 OAuth 应用创建或获授权的文件。需要读取其他应用创建的已有模型目录时，需按实际需要授权 `drive` 权限。随后重新「唤醒实例并部署」。也可通过 `EASYCOLAB_RCLONE_CONFIG` 指定其他配置文件路径；此文件含敏感授权信息，不要提交到 Git 或粘贴到聊天中。

**个人自用遇到品牌验证失败时：**

- 品牌审核与 OAuth 测试授权不是一回事。按 [Google 的个人使用豁免说明](https://support.google.com/cloud/answer/13464323)，少于 100 用户的个人应用可不经过验证使用，但可能显示未验证警告。只对自己创建且信任的应用继续授权；组织管理员或账号安全策略仍可能阻止访问。
- 暂时不发布：在 **Google Auth Platform → 目标对象 / Audience** 保持 **Testing / 测试**，将实际登录 Drive 的 Google 账号加入 **Test users / 测试用户**。然后运行 `rclone config reconnect --config ~/.config/easycolab/drive-rclone.conf "<已有 remote 名称>:"` 完成浏览器授权；仅保存 Client ID / Secret 并没有取得 Token。
- 不要填写 `google.com`、Google 隐私政策或其他不属于你的网址来验证自己的品牌，也不要对真实的问题提交错误申诉。测试授权不要求你先通过品牌审核。根据 [Google 的发布状态说明](https://support.google.com/cloud/answer/15549945)，包含 Drive 权限的测试授权及刷新令牌 **7 天后到期**，届时需再次 `reconnect`。
- 长期使用若需发布而按钮不可用，按 [rclone 官方说明](https://rclone.org/drive/#making-your-own-client-id) 提供你实际控制的网站主页和隐私政策（可用自己的域名或 GitHub Pages），说明个人工具用途及 Drive 数据如何使用。没有这些页面时先保持 Testing，不要伪造。rclone 共享客户端已进入退役流程，不建议改用共享 Client ID 来规避此问题。

程序优先使用 `easycolab_gdrive`；若专用配置只有一个 Google Drive remote，也接受 `Google Drive` 等其他名称，上传时自动映射，不改动本地配置。存在多个 Drive remote 时必须明确命名要用的那个。配置格式、加密、缺少 Token 等错误会分别提示，并在分配、切换实例或上传代码之前终止部署。

**授权成功但挂载失败：** 当前 rclone Linux 挂载需要 `fusermount3`，仅有旧版 `fusermount` 不够。部署会在具备 `/dev/fuse` 的 Colab Ubuntu 运行时自动安装 `fuse3` 系统包；已有有效挂载时跳过安装。安装失败、缺少 FUSE 设备或挂载不成功会停止部署；诊断日志为 `/content/easycolab_drive_mount.log`。无需为缺少 `fusermount3` 的错误重新做 Google 授权。

rclone 默认将真实云盘的 **`MyDrive/EasyColab_Drive`** 挂到 `/content/drive/MyDrive`，因此其模型在云盘中的真实位置为 **`MyDrive/EasyColab_Drive/models`**；官方笔记本挂载的默认位置则是 **`MyDrive/models`**，两者不要混淆。新 OAuth 应用的 `drive.file` 权限不会自动看见旧应用创建的目录。

若已在临时盘下载权重，**先不要释放实例**。在同一实例修复挂载、重新部署后点击「下载权重」，程序会复制可复用的本地权重至 Drive。确认文件已上传完成后再释放；rclone 的写缓存可能仍在后台上传，刚出现挂载点不代表所有数据都已持久化。

### HF Token 本地复用

- 模型面板的 **HF Token** 支持「保存」和「清除」；按回车或启动模型下载、加载及 ComfyUI 模型安装时，也会尝试保存非空 Token。下次启动客户端自动恢复。
- macOS 保存到本机 **钥匙串**，Windows 保存到当前用户的 **凭据管理器**，与 Tunnel Token 使用独立条目；不写入普通设置、不启用跨机器同步。保存失败会提示，仍可在当前会话使用，但不要假定下次启动还能恢复。
- Windows 旧版 `settings.json` 中的 HF Token 会迁移至凭据管理器，成功后原子移除明文字段；迁移失败时保留旧文件并暂缓写入其他设置，避免丢失令牌或继续复制明文。请检查系统凭据权限后重新「保存」或「清除」。
- 「清除」只删除 EasyColab 本地保存的 HF Token，不影响域名或 Tunnel Token，也不会在 Hugging Face 网站撤销令牌。macOS 重新编译后可能再次请求钥匙串授权，请只授权可信的 App。

## CPU / GPU 与进程监控

- 左侧 CPU/GPU 显示计算利用率，区别于已有 RAM/VRAM 占用。CPU 来自 `/proc/stat` 的采样差值，GPU 来自 `nvidia-smi`；未连接、首次采样或驱动不支持时显示 `—`，不冒充 0%。
- 点击 CPU/GPU 打开类似 htop/nvitop 的**只读**窗口，可查看 PID、进程名、CPU%、RSS、线程数，以及 GPU 计算进程的显存占用/利用率。CPU 进程以单核 100% 计，多核可超过 100%；GPU 进程利用率依赖驱动 `pmon` 支持，不能用显存占用代替。
- 进程明细使用 `/minimax_api/processes`，需要先在 API 面板**启用并同步 API Key**；无密钥返回 403、密钥不符返回 401。主状态接口增加可选利用率字段，旧客户端保持兼容。此要求不改变其他管理端点的原有鉴权范围，公网依然建议限制来源。
- 明细窗口每约 3 秒拉取后台缓存，打开时启用进程采样，关闭后约 15 秒停止明细采样，最多返回 200 个进程。不会展示命令行、环境变量、Token，也不提供 kill/终止操作；断线后清空过期明细并提示重试。
- 右侧状态摘要在连接恢复及下载/加载结束后自动更新，不再保留旧“连接中断”提示；不相关的任务错误不会被空闲轮询覆盖。可悬停查看全文，或点击展开/查看完整状态（可滚动、复制）。

---

## API 响应并发

- OpenAI Chat 和 Anthropic Messages 的 `stream=false` 请求在线程中收集、解析生成结果并统计 token，不再因等待推理而阻塞服务端事件循环、状态轮询或其他 SSE 响应。GPU 推理仍遵循原有串行锁，这不等于启用单卡并发解码。
- 请求处理任务被取消时会通知对应的生成任务停止。此修复需更新并重启云端服务端后生效；仅更新本地源码或桌面客户端不会热替换正在运行的 Python 进程，也不能替代公网 HTTP/2／代理链路故障的排查。

---

## Cloudflare 自定义域名（可选）

默认仍生成临时 `*.gradio.live` 地址。若域名已托管在 Cloudflare，可配置**远程管理的命名 Tunnel**，让 WebUI、桌面客户端和 `/v1/*` API 共用固定地址，例如 `https://ai.example.com`。只新增 DNS 记录还不够；Colab 无固定公网 IP，必须运行 Tunnel 连接器。

### 1. Cloudflare 控制台配置

1. 在 **Networking → Tunnels**（部分界面为 Zero Trust → Networks → Tunnels）创建 Cloudflared Tunnel，例如 `easycolab`。
2. 保存连接器安装命令中的 **Tunnel Token**，只取 Token 本身，不是 Cloudflare API Token，也不要复制整条安装命令。EasyColab 会在 Colab 上自动下载并运行 `cloudflared`，不需要在 Mac 安装常驻服务。
3. 在该 Tunnel 的 **Routes → Add route → Published application**（旧界面为 **Public Hostname**）添加 `ai.example.com`，**Service URL** 填 `http://localhost:7860`，**Path 留空**。控制台会创建指向 Tunnel 的 DNS 记录；若同名记录已存在，先解决冲突。推荐一级子域名，多级子域名可能需要额外证书。
4. 同一 Tunnel 不要同时连接多个独立 Colab 实例，否则 Cloudflare 可能把请求分发到不同实例；不同实例请使用不同 Tunnel / 域名。

### 2. EasyColab 配置

- **macOS / Windows 一键唤醒**：展开左侧「Cloudflare 自定义域名」，启用固定域名，填写 `https://ai.example.com` 和 Tunnel Token，点击「保存配置」或直接「唤醒实例并部署」（唤醒前自动保存）。域名和开关保存在普通设置中；Token 保存在 **macOS 钥匙串 / Windows 凭据管理器**，下次启动会自动读取，不写入 UserDefaults、`settings.json` 或 Git。仅连接一个已运行的服务时，直接填「服务地址」即可，不需要 Token。
- **复用与清除**：Tunnel Token 不是一次性口令，同一 Tunnel 可以跨 Colab 重启重复使用；在 Cloudflare 轮换 Token 后需要更新并保存一次。关闭固定域名开关不会删除凭证；点击「清除 Token」会删除本机保存的 Token，保留域名，也不会撤销 Cloudflare 上的 Token 或中断已运行的隧道。
- **系统凭证权限**：Token 仅为当前系统用户在本机保存，不启用 iCloud / 跨机器凭证同步。macOS 首次访问或重新编译 App 后可能提示钥匙串授权；仅对你自己编译且信任的 EasyColab 授权。保存失败会明确提示并停止此次自定义域名唤醒，不会回退到明文存储；未保存的新输入在退出 App 后仍会丢失。Windows 源码客户端在非 Windows 平台预览时不支持凭据管理器。
- **Colab 笔记本**：在左侧钥匙图标 **Secrets** 中添加 `CLOUDFLARE_TUNNEL_TOKEN` 并允许本笔记本访问；在第四步设置 `EASYCOLAB_PUBLIC_URL = "https://ai.example.com"`。留空则使用默认随机地址，不读取 Secret；不要把 Token 写进单元格。
- **直接运行 Python**：将 `EASYCOLAB_PUBLIC_URL` 与 `CLOUDFLARE_TUNNEL_TOKEN` 注入进程环境，再运行 `python app.py`，并确保同目录有 `easycolab_tunnel.py`、`easycolab_vllm.py`。不要把真实 Token 放进命令参数、脚本或 Git。

启用后会关闭 Gradio 公网分享，等待命名 Tunnel 连接 Cloudflare 成功后返回固定地址；失败会报错，不会偷偷回退到随机地址。更换配置需重新部署。域名会保留，但释放 Colab 后服务仍会离线，重新部署到同一 Tunnel 后恢复。ComfyUI 的独立 `8188` 端口 / 临时隧道不变。

### 安全与排障

- **固定域名不是鉴权**，Tunnel Token 只授权连接器，不验证访问者。现有 API Key 只保护 `/v1/*` 网关，**不保护整个 WebUI 和 `/minimax_api/*` 管理接口**。发布前应在 Cloudflare 对该主机名设置访问限制，例如用 WAF 自定义规则阻止非可信出口 IP；不要向不可信网络裸露管理界面。
- 浏览器可使用 Cloudflare Access 登录保护；当前桌面客户端**不支持 Access 交互登录或 Service Token 请求头**，仅在浏览器登录不会让桌面请求自动获权。需要桌面连接时使用兼容的来源 IP 限制等策略，不要为整个站点配置无条件 Bypass。
- Headless 部署通过临时文件上传 Tunnel 配置，本地文件权限为 `0600`，上传后删除；远端在启动引导代码中收紧权限、读取并删除。Token 不放入 Jupyter 执行代码、命令行参数或客户端日志。泄露后请在 Cloudflare 轮换 Token。
- 连接超时 / 进程退出：检查 Token 是否属于正确 Tunnel、Colab 是否能出站连接 Cloudflare `7844` 端口。`502`：检查 Service URL 和服务进程；`404` / 证书错误：检查主机名、Path、DNS 和证书；`403` / 登录页：检查 WAF / Access 策略。程序检测的是连接器就绪，不能替代 Cloudflare 路由、DNS 与策略配置验证。
- 唤醒失败时，客户端现在会显示脱敏的服务端 / 连接器日志和退出码，并区分「进程退出」与「180 秒启动超时」。`Provided Tunnel token is not valid` 表示 Token 格式不对；授权拒绝可能是 Token 失效；DNS、连接超时应检查出站网络。看到笼统的 `custom tunnel failed` 表示仍在使用旧打包资源，请重新编译客户端后再部署。失败不会自动释放 GPU 实例，排查结束后请手动释放，避免继续计费。
- Cloudflare 仍有套餐相关的上传大小和请求超时限制，大文件上传 / 长请求可能遇到 `413` / `524`；自定义域名不会消除这些限制。

官方参考：[创建远程管理 Tunnel](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/create-remote-tunnel/) · [连接器参数与 Token](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/configure-tunnels/run-parameters/)。

---

## 隐私与安全建议

1. **录屏 / 截图防泄密开关**：在左侧「服务地址」输入框旁提供了 **打码保护开关**（macOS 为眼睛图标，Windows 为「打码」按钮）。在录制教程、直播或截图分享前，请开启打码隐藏服务地址、自定义域名与运行日志中的 URL 主机名及账号邮箱。打码不能代替访问鉴权。
2. **开启 API Key 鉴权**：对外使用 Qwen API 网关时，请保持「启用 API Key 鉴权」处于开启状态。
3. **本地凭证与数据目录**：
   - Google OAuth 授权凭证仅保存在本机 `~/.config/colab-cli/token.json`（Windows 为 `%USERPROFILE%\.config\colab-cli\token.json`），不会上传至任何第三方服务器。
   - Windows 客户端本地配置文件位于 `%LOCALAPPDATA%\EasyColab\settings.json`，成片默认保存于 `%USERPROFILE%\Videos\EasyColab`。

---

## 免责声明与合规说明 (Disclaimer)

- **非官方独立项目**：EasyColab 是社区开发的独立开源客户端与辅助工具，**与 Google LLC、Google Colab、MiniMax、阿里巴巴通义千问（Qwen）等官方机构无任何隶属、赞助或背书关系**。
- **平台服务条款（ToS）提示**：
  - 客户端内的「免网页一键唤醒」功能底层基于开源社区库 [`google-colab-cli`](https://pypi.org/project/google-colab-cli/) 与自购付费计算单元（Paid Compute Units）交互，**强烈建议仅在已订阅 Colab Pro / Pro+ / Google AI Ultra 的自有付费账号上合理自用**。
  - 请勿在 Google Colab 免费层（Free Tier）上滥用无网页后台连接，严禁用于加密货币挖矿、批量多号滥用或违规算力转售。使用第三方客户端连接云端运行时可能受平台策略变更影响，相关账号风险由使用者自行评估并承担；若追求 100% 官方网页交互体验，请使用仓库内置的 `EasyColab_Server.ipynb`。
- **模型与上游组件许可证**：
  - 本仓库**不包含也不分发任何模型权重或 GPL 源码**。所有模型权重均由用户在运行时从 Hugging Face 官方仓库自行下载，须遵守各模型原始许可证（如 *MiniMax-H3 Community License Agreement*、*Apache-2.0*、*Tongyi Qianwen License* 等）。
  - 云端 ComfyUI 工作台在用户个人虚拟机内按需拉取官方仓库并通过独立进程 HTTP API 通信，ComfyUI 本体遵循其 **GPL-3.0** 协议。

---

## 致谢 (Acknowledgements)

感谢以下优秀的开源项目与模型团队：
- [DiffSynth-Studio](https://github.com/modelscope/DiffSynth-Studio)
- [ComfyUI](https://github.com/comfyanonymous/ComfyUI) & [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager)
- [MiniMax-H3](https://github.com/MiniMax-AI/MiniMax-H3)
- [Qwen](https://github.com/QwenLM) & [Unsloth](https://github.com/unslothai/unsloth)
- [llama.cpp](https://github.com/ggml-org/llama.cpp)
- [google-colab-cli](https://pypi.org/project/google-colab-cli/)

---

## License

本项目源代码基于 [Apache License 2.0](./LICENSE) 开源发布。
