# EasyColab

[简体中文](./README.md) | **English**

**EasyColab** is a native desktop Multimodal AI Studio built for **macOS and Windows**, powered by Google Colab high-VRAM cloud GPUs (macOS native SwiftUI client + Windows PySide6/Qt6 desktop client + cloud multi-model acceleration engine).

Optimized out of the box for **Google Colab G4 (`NVIDIA RTX PRO 6000 Blackwell` · `96 GB` VRAM + `176 GB` System RAM)** as well as `H100 / A100 / L4` runtimes, EasyColab supports headless one-click runtime wake & deployment, persistent model caching on Google Drive, multi-model VRAM co-residency, real-time spline telemetry charts, instant Chinese/English UI switching, and automatic idle runtime release to save Compute Units.

![EasyColab Studio Screenshot](./shot.png)

---

## Key Features

- **Cross-Platform Native Studio + Bilingual UI Toggle + Interactive Onboarding (1:1 Parity Across macOS & Windows)**
  - **macOS Client** is crafted natively with SwiftUI + AppKit; **Windows Client** is built with PySide6 (Qt6 + FFmpeg multimedia pipeline) featuring Windows 11 immersive light/dark title bars and high-DPI scaling. Both include a **4-step interactive onboarding wizard** on first launch with zero-config bridge initialization.
  - Built-in **one-click Chinese / English (`中文 / EN`) live UI toggle** (defaults to Chinese), persisting language preferences automatically without restarting the app.
  - Real-time smooth Catmull-Rom spline telemetry charts for cloud **GPU VRAM / System RAM / Disk Space** (supporting both split and combined overlay modes), paired with official **Compute Unit (CU) balance** and hourly burn-rate tracking.
  - Built-in **30-minute idle auto-sleep watchdog** and one-click **"Release All Instances"** to prevent forgotten runtimes from draining your CU quota.

- **Four Flagship Open-Source Multimodal Engines Out of the Box**
  1. **`MiniMax-H3 (Native BF16)` · 4–15s Cinematic Video with Native Stereo Audio**
     - Supports Text-to-Video+Audio, First-Frame-to-Video, and First/Last-Frame camera transitions, natively generating `24 FPS` video paired with `32 kHz` stereo soundscapes, dialogue, and music.
     - **G4 176 GB Dual-Backbone DDR5 Hot-Standby Acceleration**: Keeps both the `32B Text Encoder` and `33B DiT Backbone` resident in high-speed DDR5 RAM — delivering `0 ms` prompt reuse on consecutive generations and ~`8–12s` PCIe swap-in when editing prompts.
  2. **`ComfyUI Node Studio` · Google Drive Persistence + 4 Curated Ready-to-Run Workflow Packs**
     - One-click deployment of ComfyUI + ComfyUI-Manager over a free encrypted Cloudflare HTTPS tunnel, with `custom_nodes`, `models`, and `workflows` automatically symlinked and persisted to Google Drive.
     - Ships with four curated Image-to-Video & First/Last-Frame workflow packs (**Wan2.2 14B**, **MiniMax-H3 Turbo**, **LTX-2.3 (22B)**, and **HunyuanVideo 1.5**) featuring one-click model provisioning.
  3. **`Qwen3.8-27B (UD-Q4_K_M + MTP Speculative Decoding / BF16)` · 100 tok/s Vision Chat & Dual-Protocol API Gateway**
     - Supports up to `256K` context length, deep chain-of-thought reasoning, and multimodal image analysis / prompt reverse-engineering.
     - Built-in public API gateway compatible with both **OpenAI (`/v1/chat/completions`)** and **Anthropic (`/v1/messages`)** (with Bearer / `x-api-key` authentication), ready to plug directly into **Claude Code**, **Cursor**, and custom agent workflows.
     - Optional [**DeepSeek-V4-Pro-Qwen3.5-9B-UNCENSORED-heretic**](https://huggingface.co/xtools-at/DeepSeek-V4-Pro-Qwen3.5-9B-UNCENSORED-heretic): a Qwen3.5-9B reasoning distillation using the BF16 chat, vision, and dual-protocol gateway path. Downloads approximately `18 GiB` (4 main shards plus index-required MTP weights; MTP speculative decoding is not enabled). Allow at least approximately `20 GiB` of free VRAM to load; long contexts need additional VRAM. Use the full repository ID as the API `model`.
  4. **`Qwen-Image-2.1` & `Z-Image-Turbo` · 2K Poster Generation & Multi-Image Instruction Editing**
     - High-fidelity bilingual typography rendering, natural-language multi-image editing, and 8-step ultra-fast photorealistic generation. All generated MP4 videos and PNG images are automatically pulled back to your local machine (macOS: `~/Movies/EasyColab`, Windows: `%USERPROFILE%\Videos\EasyColab`).

---

## Quick Start

### Browser Controls from Another Computer

Use the standalone [`EasyColab_Control.ipynb`](EasyColab_Control.ipynb), not the legacy `EasyColab_Server.ipynb`. Upload it at [Google Colab](https://colab.research.google.com/), save a copy to your Drive, and bookmark your copy. No desktop app or local rclone authorization is needed.

1. Sign in to the Google account holding your weights. Choose **Runtime → Change runtime type → G4 / RTX PRO 6000 96GB**, then Connect. GPU allocation still depends on Colab quota and availability.
2. Add `CLOUDFLARE_TUNNEL_TOKEN` and `EASYCOLAB_API_KEY` in Colab Secrets and grant this notebook access. The API key may match your desktop key. Never paste credentials into notebook source or upload rclone credentials.
3. Run the three code cells in order and authorize the official Drive mount. Fill in your HTTPS hostname and model directory, then click **Prepare Environment → Start API → Load Model**. Wait for status `loaded: true`; use the full jpezzulli ModelOpt repository ID and `https://your-hostname/v1` in your API client.
4. When finished, confirm and click the red **Release GPU** button. Unloading the model or closing the browser does not release the instance. If the panel is unavailable, terminate the corresponding session through **Runtime → Manage sessions**.

The default reads `MyDrive/EasyColab_Drive/models`, matching desktop persistence. Change it to `MyDrive/models` if that is where your old official notebook stored the checkpoint. Cloud weights are read-only: the controller validates the pinned manifest and sizes, stages to local SSD, and reuses complete local shards. It does not redownload 126 GiB or delete old vLLM caches. Missing weights must first be completed using the desktop workflow.

This mode exposes the Penny Royal API and authenticated control routes, not the legacy MiniMax WebUI or all desktop management endpoints. It downloads and SHA256-verifies gateway modules from fixed EasyColab commit `94b32ca`, including SSE fixes, and reuses the existing SGLang backend. First preparation targets Colab Ubuntu 24.04 / Python 3.12, installs CUDA Toolkit 13.3, GCC14, Rust and isolated Python environments, without upgrading the GPU driver. Releasing the instance loses the toolchain and SSD cache.

Stop any old instance using the same Cloudflare Tunnel before starting another, otherwise requests may reach different servers. The API defaults to release after 30 idle minutes; environment preparation has no idle watchdog yet. Run All mounts Drive and displays controls but never automatically builds, loads or releases. Isolated checks cover sources, paths, reuse, authentication and lifecycle; Google consent and a complete fresh-runtime installation require the user's Colab session. Testing never releases the user's live GPU.

### Experimental ModelOpt NVFP4 Backend: SGLang / Penny Royal

The catalog now includes **OrcaRouter Flash-Next ModelOpt · Penny Royal** alongside the existing `orcarouter/...-NVFP4` vLLM model. Existing weights, vLLM runtime and launch options remain unchanged.

- Model: [`jpezzulli/OrcaRouter-Qwen3.8-Flash-Next-Uncensored-ModelOpt-NVFP4`](https://huggingface.co/jpezzulli/OrcaRouter-Qwen3.8-Flash-Next-Uncensored-ModelOpt-NVFP4), revision `f24d2b68ff2814f24455ae86717be276619b5664`: 206 weight files, **125.91 GiB**, including roughly 47.7 GiB of FP8 PLE tables. This is a separate quantization of the same source, not renamed old weights.
- Runtime: Penny Royal 3.1.6, source `202f266be2d46453e098792fa39057e859fb8095`, isolated under `.easycolab-pennyroyal`. API requests use the new full repository ID; internal ID is `qwen38_flash_next_modelopt_sglang`. No silent vLLM fallback.
- Initial experimental profile: one SM120 RTX PRO 6000 96GB, at least 72 GiB available RAM, 4K–32K context, one request, ModelOpt NVFP4, FP8 PLE on CPU, native NEXTN MTP (3 steps / 4 tokens), small CUDA Graphs and BF16 KV. Penny Royal converts eligible dense projections, HC and lm_head to rowwise FP8 online; not every BF16 shard executes in BF16. No 524K, FR-Spec, HiCache/NIXL or DFlash2 yet; full Penny Royal benchmark numbers do not apply.
- Weight download and Drive verification reuse existing byte-based tracking but store under separate `models/jpezzulli/...` paths. Loading needs approximately 126 GiB of local SSD plus a 22 GiB margin, with at least 25 GiB more for environment builds. A Colab disk retaining the old 171 GiB cache may not fit both; old files are never deleted automatically.
- Source builds need Linux, a CUDA 13.3 toolkit, compatible C/C++ compilers, Rust/Cargo, Python 3.12 (preferred) and Git. Override toolchains through `EASYCOLAB_SGLANG_CUDA_HOME`, `EASYCOLAB_SGLANG_CC`, and `EASYCOLAB_SGLANG_CXX`. Installing a toolkit does not upgrade Colab's host driver; only the combination recorded below has been hardware-tested.
- Run `python easycolab_sglang.py preflight`, then `python easycolab_sglang.py prepare` on the GPU host, or provide `EASYCOLAB_SGLANG_PYTHON=/path/to/pennyroyal/.venv/bin/python`. Never point it at `.easycolab-vllm-venv`. Failed setup does not unload the old model; actually switching models requires unloading it because both cannot reside on one card.

Colab Ubuntu 24.04's GCC 13 does not support the `__has_feature` macro used by this FlashInfer patch; compilation was observed to fail. Fresh instances require system-toolchain setup; the app does not install system packages or upgrade drivers automatically. Run the following in the **Colab GPU terminal**, with root access and NVIDIA's CUDA apt repository already configured, not on your Mac/Windows host:

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

The isolated bootstrap includes `wheel-stub==0.5.0`, required by NVIDIA's `cuda-tile` prerelease packaging to locate its official wheel. Do not bypass the SM120 build or remove quantization settings to silence compatibility errors.

**Hardware smoke test, 2026-11-09:** one Colab RTX PRO 6000 96GB, driver 580.82.07, CUDA Toolkit 13.3.1, GCC 14 and Python 3.12 successfully built the SM120 fused MoE kernel and started the 4K profile. Reading 206 weight shards from local SSD took about 7m53s; the complete main-model loading stage took about 500s, plus another 206s for MTP. The first startup through completion of two requests took about 795s, including online conversion, JIT and warmup but excluding dependency installation. Target-verify and draft decode/extend CUDA Graph capture succeeded; upstream automatically disabled prefill graphs. Health returned 200; the English request returned `OK`, and the Chinese request returned a complete relevant sentence. This verifies basic inference, not a controlled comparison against vLLM. 32K, multimodal input, tool calls and long-running stability still need hardware testing. After Drive synchronization, rclone verified 219 matching files; the compiled environment and SSD cache are still ephemeral.

Sources: [pinned Penny Royal build guide](https://github.com/jpezzulli/sglang-rtxpro6000/blob/pennyroyal-v3.1.6/BUILD.md), [checkpoint card](https://huggingface.co/jpezzulli/OrcaRouter-Qwen3.8-Flash-Next-Uncensored-ModelOpt-NVFP4), and [SGLang single-GPU recipe](https://docs.sglang.io/cookbook/autoregressive/Qwen/Qwen3.8-Flash-Next). Catalog presence alone is not evidence of validated performance or stability.

### Qwen3.8-Flash-Next NVFP4 on one G4 96GB GPU

The catalog includes [orcarouter/Qwen3.8-Flash-Next-Uncensored-NVFP4](https://huggingface.co/orcarouter/Qwen3.8-Flash-Next-Uncensored-NVFP4), pinned to `9c6f1345b523a9d9d70b41542a63b39e3c9b7ca6`. It is **not the 27B model**: 17 main shards plus MTP total **170.9 GiB / 183.5 GB**. The large BF16 PLE shard is about **95.4 GiB**; excluding PLE and MTP leaves about **70.7 GiB** of main weights, before runtime, vision and KV memory.

- Accept the gated repository terms on HF and enter an authorized **HF Token**, not a Cloudflare token. Observe the model's research-use terms.
- Use an RTX PRO 6000 **Blackwell 96GB** with high host RAM. Loading checks for at least 90 GiB total VRAM, 90% free VRAM and **112 GiB available host RAM** after unloading existing models. Hopper/Ampere/L4/T4 are rejected; there is no implicit BF16 fallback.
- Reserve approximately **180 GiB** on Drive. Downloaded weights/configuration persist under `models/orcarouter/Qwen3.8-Flash-Next-Uncensored-NVFP4/`. Restarts reuse Drive files but must still load PLE into host RAM and remaining weights into VRAM. No second PLE copy is staged into `/dev/shm`; lazy safetensors loading avoids reading the entire giant shard into another RAM buffer. Drive loading can still be slow.
- Select **4K–32K context** and Load to VRAM. The first load creates `.easycolab-vllm-venv` with `vllm==0.33.0` and `transformers==5.20.1` (within vLLM's `>=5.16.1,<5.21.0` constraint), leaving the main server's PyTorch unchanged. Linux, Python 3.11+, a driver compatible with the vLLM CUDA wheel and local installation space are required. Set `EASYCOLAB_VLLM_PYTHON=/path/to/venv/bin/python` on the server to use a prepared compatible environment.
- The conservative single-GPU profile uses TP1, `--engram-config '{"cpu_offload":true}'`, lazy safetensors loading, one concurrent request, 2048-token prefill chunks, BF16 KV, and disables FlashInfer autotune, CUDA graphs and MTP. It supports up to two images and no video. Establish a stable baseline before experimenting with MTP or longer contexts; community throughput from other checkpoints is not a guarantee.

Use the full repository ID as the API `model`. Desktop chat/images and the OpenAI/Anthropic gateways share the vLLM streaming path, including tool calls. Thinking defaults to `medium`; `chat_template_kwargs.enable_thinking=false` disables it. For VRAM pressure start at 4K/8K and stop other GPU tasks. Shorter context cannot remove the approximately 95 GiB host-RAM requirement. Failed starts clean up the child process and report diagnostics.

The isolated environment uses `venv --without-pip` and the main interpreter's [`pip --python`](https://pip.pypa.io/en/stable/topics/python-option/) bootstrap (main pip ≥22.3). This works when Colab's Python lacks `ensurepip`, without installing system packages that upgrade shared Python. pip, vLLM and Transformers are installed only in the isolated environment. Installation output streams to the client logs; failures include the exit code and sanitized log tail. Existing model weights are not downloaded again.

**Qwen4 mixed-precision compatibility fix:** Stock vLLM 0.33.0 fuses FP8 Q/K/V with the BF16 QSA indexer, causing `Found different quantization schemes for the shards`. The managed environment backports upstream's conditional fusion: omit the indexer from the static QKV mapping and fuse it only when quantization methods are compatible. FP8/NVFP4/BF16 weights remain unchanged; quantization metadata is not removed and weights are not downloaded again. The patch is limited to vLLM 0.33.0, validates source and backs up originals. Custom `EASYCOLAB_VLLM_PYTHON` environments are not modified automatically; install a version containing the corresponding fix yourself. Startup diagnostics retain the original exception, not just `Engine core initialization failed`.

**FlashInfer kernels:** The managed environment pins `flashinfer-python==0.7.2.post1`, installs matching `flashinfer-cubin` from FlashInfer's official wheel index, and runs `python -m flashinfer install-jit-cache-wheel --mode minimal` for the installed PyTorch CUDA version and visible GPU (`cu130/sm120f` on this RTX PRO 6000), rather than downloading every architecture. Installation has timeouts and streamed logs. The isolated environment's `bin` is prepended to PATH so its `ninja` is visible, and `CUDA_HOME` is detected from `nvcc`. Precompiled packages do not cover every JIT specialization, so initial loading can still compile kernels. Memory-intensive autotuning/CUDA Graphs remain disabled; warnings are fixed rather than suppressed. See [FlashInfer installation](https://docs.flashinfer.ai/installation.html) and [upstream conditional fusion](https://github.com/vllm-project/vllm/blob/main/vllm/models/qwen4_exp/nvidia/qsa.py).

**vLLM local SSD staging:** Lazy safetensors mmap can be extremely slow on rclone FUSE (about 4 MiB/s in this run), while eager loading would compete with the 95 GiB resident PLE table. For rclone mounts, `rclone copy` now stages weights in parallel into the runtime's `models/<repo>`, checks sizes, and refreshes metadata before local mmap loading. Initial staging needs about 171 GiB plus a 22 GiB safety margin. Complete local shards are reused and Drive originals remain unchanged. Progress logs appear every five seconds; insufficient space fails explicitly without deleting files or silently returning to the slow path. Local staging disappears when the instance is released; the Drive copy remains reusable.

**Hardware verification (2026-11-09):** On a Colab RTX PRO 6000 Blackwell Server Edition (94.97 GiB VRAM), TP1, 4K context and PLE CPU offload, all 18 weight files loaded, health checks passed, and a short OpenAI Chat Completions request returned `OK` (18 input tokens, 2 output tokens). Model loading reported about 71.02 GiB of GPU memory, excluding all KV/runtime peak overheads. FlashInfer GDN prefill and sampling were enabled; MoE selected the compatible Marlin path. 32K context, real image requests, concurrency/stability, and formal throughput benchmarks remain unverified.

Sources: [serving article](https://www.orcarouter.ai/blog/qwen3-8-flash-next-uncensored-nvfp4), [vLLM EngramConfig](https://github.com/vllm-project/vllm/blob/v0.33.0/vllm/config/engram.py), [pinned-host PLE implementation](https://github.com/vllm-project/vllm/blob/v0.33.0/vllm/models/qwen4_exp/common/ngram_embedding.py), [loading strategies](https://github.com/vllm-project/vllm/blob/v0.33.0/vllm/config/load.py). This integration follows upstream support; local checks are not a full Colab GPU inference test with these gated weights.

### System Requirements
- **Operating System**:
  - **macOS**: macOS 13.0 (Ventura) or later (Apple Silicon / macOS Sonoma & Sequoia recommended)
  - **Windows**: Windows 10 (1903+) or Windows 11 64-bit (x64)
- **Cloud Account**: A Google account subscribed to **Google Colab Pro / Pro+ / Google AI Ultra** with available Compute Units (CU). Free-tier users should follow the *"Run via Official Google Colab Web UI"* section below.

---

### macOS Client

#### Option 1: Build & Run Locally with One Command (Recommended, No Gatekeeper Prompt)
Requires Xcode Command Line Tools (`xcode-select --install` if not already installed):

```bash
git clone https://github.com/<your-username>/EasyColab.git
cd EasyColab
bash macos_app/build_macos_app.sh
open EasyColab.app
```

> The build script automatically bundles `app.py`, `colab_bridge.py`, `easycolab_tunnel.py`, `easycolab_vllm.py`, and `EasyColab_Server.ipynb` into `EasyColab.app/Contents/Resources/`. You can drag `EasyColab.app` directly into `/Applications` for standalone use; the first time you click **Bind**, EasyColab automatically creates an isolated Python environment at `~/Library/Application Support/EasyColab/venv` and installs the bridge dependencies.

#### Option 2: Download Prebuilt `.app` from GitHub Releases
If you download an unsigned/unnotarized `.app` archive and macOS displays *"Cannot verify developer / App is damaged"* on first launch, clear the quarantine attribute once in Terminal:

```bash
xattr -cr /Applications/EasyColab.app
```

---

### Windows Client

#### Option 1: Download Portable `.zip` (Zero Python Dependency, Recommended)
1. Download `EasyColab-Windows-x64.zip` from GitHub Releases (or from repository **Actions -> Build EasyColab Windows App** artifacts).
2. Extract to any folder and double-click `EasyColab\EasyColab.exe` (bundles an embedded Python runtime, Qt6 UI libraries, FFmpeg audio/video codecs, and the `colab_bridge` cloud launcher — no system Python required).
3. If Windows SmartScreen displays *"Windows protected your PC"*, click **More info -> Run anyway**.

#### Option 2: Build Standalone `.exe` Locally on Windows
With 64-bit Python 3.10–3.13 installed, run the one-click build script from the repository root to generate `dist\EasyColab\EasyColab.exe` and `EasyColab-Windows-x64.zip`:

```bat
REM Double-click or run in CMD:
windows_app\build_windows_app.bat
```

Or in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\windows_app\build_windows_app.ps1
```

#### Option 3: Run Directly from Source (Windows / macOS Cross-Platform Preview)

```bash
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS:   source .venv/bin/activate
pip install -r windows_app/requirements-windows.txt
python windows_app/easycolab_win.py
```

---

### Run via Official Google Colab Web UI (For Colab Free Tier / Browser Users)
1. Open [Google Colab](https://colab.research.google.com/) and upload `EasyColab_Server.ipynb` from the repository root (or click **Export / Locate `.ipynb` Notebook** inside the app's Onboarding Guide).
2. In the Colab menu bar, select `Runtime -> Change runtime type`, choose `G4` / `A100` / `L4` GPU, and run the cells in order.
3. Copy the printed `https://xxxx.gradio.live` URL into the **Server URL** field on the left sidebar of the desktop client and click **Connect**.

---

## Persistent Model Storage & Custom Directories

Keep `MOUNT_GOOGLE_DRIVE = True` in the notebook's second cell, optionally edit `EASYCOLAB_MODEL_DIR`, authorize the Drive mount, and then start the server. The default model location is:

```text
/content/drive/MyDrive/models/<Hugging Face owner>/<model repository>/
```

- Set `EASYCOLAB_MODEL_DIR` to a directory such as `/content/drive/MyDrive/AI/models`. It must be a subdirectory of the mounted `MyDrive`; restart the server after changing it. Standalone `app.py` also accepts this environment variable, with precedence over the compatible `DIFFSYNTH_MODEL_BASE_PATH` setting.
- "Download Weights" writes directly to Drive and saves the required tokenizer, processor, configuration, and chat-template files. Completion is reported only after writes and configuration-manifest checks succeed. Full storage, write failures, and disconnected mounts produce errors instead of silently falling back to temporary storage.
- Separate **Download / reuse** and **Drive upload** byte counters use actual weight sizes, not shard counts. During standard HF fallback downloads, the current file's counter updates on completion; preallocated `.part` sizes are never treated as completed downloads.
- rclone write caching is not persistence. After downloading, the task waits for uploads, queries Drive directly for every required weight/configuration file size and the metadata manifest's MD5, and excludes dirty cache entries. Only then is `drive_persisted=true`; this is not a full content-hash check of all weights. Unavailable verification, repeated query failures, or a two-hour wait timeout produce an explicit error while retaining complete local files for **Verify Weights** retries. Do not release the runtime while unconfirmed.
- New desktop-managed mounts expose monitoring only on `127.0.0.1` with random credentials in a cloud-side `0600` file, never sent to clients or exposed publicly. Existing mounts are not restarted and report completed remote files only; large in-flight shards can leave the confirmation counter unchanged. Even 100% sent still requires remote confirmation.
- The official notebook's `drive.mount()` lacks this independent rclone verification channel: weights remain downloadable/loadable, but persistence is explicitly **unconfirmed**, not inferred from a mounted path. Use a desktop-managed rclone mount for independent verification. Updating a client does not interrupt existing downloads; deploy the updated server only after current work finishes.
- Mount the same Drive on subsequent starts to reuse weights and configuration. Repeating "Download Weights" skips existing files. Completed configuration is checked using `.easycolab-metadata.json`, with missing files fetched again. Installing runtime dependencies may still require network access.
- Existing `EasyColab_Models`, `Aevix_Models`, `MiniMax_H3_Models`, and default `models` directories remain readable. "Download Weights" copies existing weights from legacy directories or local caches into the configured directory without downloading them again or deleting the originals; allow space for the copies during migration.
- Drive is persistent storage, not GPU VRAM. Each fresh instance still reads weights into RAM/VRAM; existing load-time RAM/NVMe staging remains available. Initial download speed is limited by Drive write throughput.
- Disabling mounting on an instance with no other Drive mount explicitly uses temporary storage, which is lost when the instance is released. Merely configuring rclone or starting ComfyUI no longer marks ordinary models as persisted.

### Drive Authorization for Headless Deployment

The desktop sidebar now offers **Connect Google Drive**:

1. Existing local rclone configurations supply the OAuth Client ID / Secret automatically. Choose **Connect / Reauthorize** and complete consent in your default browser, without installing or manually configuring local rclone.
2. On a new computer, **Import Client JSON** once using your own **Desktop app** OAuth client downloaded from Google Cloud, then connect. Colab login does not automatically transfer that JSON between computers; this uses your own client, not Colab's bundled OAuth client. Do not share or commit it.
3. The default request is `drive.file`. Explicitly select **Access existing Drive files (full Drive scope)** for directories created by other apps. Add the signing-in account as a test user and enable the Drive API in the matching project.
4. Authorization uses a temporary `127.0.0.1` callback, OAuth state and PKCE, with a three-minute consent timeout. The Drive API is checked before atomically saving `~/.config/easycolab/drive-rclone.conf` (Windows: `%USERPROFILE%\.config\easycolab\drive-rclone.conf`). Cancellation/failure does not proactively delete old credentials. `EASYCOLAB_RCLONE_CONFIG` remains supported.
5. Imported client settings use `~/.config/easycolab/drive-oauth-client.json`. These private files are `0600` on macOS/Linux; retain private user-profile permissions on Windows. They contain credentials: do not share plaintext copies on Drive. Testing grants still expire after about seven days; reconnect to renew. New authorization is uploaded on the next **Wake & Deploy**, not by interrupting the current server.

Desktop **Wake & Deploy** uses rclone rather than the notebook's interactive `drive.mount()`. It now verifies the mount before starting a new server and sets `EASYCOLAB_REQUIRE_DRIVE=1`. API 403, expired authorization, and mount failures stop deployment instead of silently using temporary storage; they do not release the existing instance.

**Colab login does not guarantee Drive access.** `SERVICE_DISABLED`, `accessNotConfigured`, or `quota project` errors indicate that the credentials' OAuth project lacks an enabled Drive API or usable quota configuration. Logging into the same bundled client again usually cannot fix this. Use the official notebook mount, or configure separate Drive authorization for headless deployment:

1. Follow [rclone's official guide](https://rclone.org/drive/#making-your-own-client-id) to enable **Google Drive API**, configure OAuth consent, and create a desktop OAuth client in your own Google Cloud project. Authorize using that project's client; enabling the API in an unrelated project does not repair existing credentials.
2. Install rclone locally and run the following commands. Create a **Google Drive** remote named **`easycolab_gdrive`**, enter your Client ID / Secret, and complete browser authorization. Do not enable rclone configuration-file encryption for this dedicated file; deployment must be able to read it.

   ```bash
   mkdir -p ~/.config/easycolab
   rclone config --config ~/.config/easycolab/drive-rclone.conf
   chmod 600 ~/.config/easycolab/drive-rclone.conf
   ```

3. Choose `drive.file` for new dedicated storage; it only accesses files created by or explicitly authorized for that OAuth app. Accessing existing model directories created by other apps may require the broader `drive` scope. Then run **Wake & Deploy** again. `EASYCOLAB_RCLONE_CONFIG` can override the config path. The file contains sensitive credentials: never commit it or paste it into chat.

**If brand verification blocks personal use:**

- Brand review is separate from OAuth test authorization. [Google's personal-use exemption](https://support.google.com/cloud/answer/13464323) permits personal apps with fewer than 100 users to operate without verification, potentially showing an unverified-app warning. Only authorize your own trusted app; organization or account security policies may still block access.
- To proceed without publishing, keep **Google Auth Platform → Audience → Testing** and add the actual Drive account under **Test users**. Run `rclone config reconnect --config ~/.config/easycolab/drive-rclone.conf "<existing remote name>:"` and complete browser authorization. Saving Client ID / Secret alone does not obtain a token.
- Do not use `google.com`, Google's privacy policy, or someone else's website to verify your own brand, or appeal genuine problems as incorrect. Test authorization does not require passing brand review first. [Google documents](https://support.google.com/cloud/answer/15549945) that testing grants involving Drive scopes, including refresh tokens, **expire after seven days**; reconnect when necessary.
- For long-term use, if publishing is unavailable, [rclone's official guide](https://rclone.org/drive/#making-your-own-client-id) calls for an actual homepage and privacy policy under your control (your own domain or GitHub Pages), describing the personal tool and its use of Drive data. Stay in Testing if those pages are unavailable; do not fabricate them. rclone's shared client is being retired and is not recommended as a workaround.

The bridge prefers `easycolab_gdrive`. If the dedicated configuration contains exactly one Google Drive remote, other names such as `Google Drive` are also accepted and mapped during upload without changing the local file. Multiple Drive remotes require explicitly naming the intended one. Format, encryption, and missing-token errors have separate diagnostics and stop deployment before instance allocation, switching, or code upload.

**Authorization succeeds but mounting fails:** The current Linux rclone mount requires `fusermount3`; legacy `fusermount` alone is insufficient. Deployment automatically installs the `fuse3` system package on Colab Ubuntu runtimes with `/dev/fuse`, skipping installation if a valid mount already exists. Installation failure, a missing FUSE device, or a failed mount stops deployment. Mount diagnostics are in `/content/easycolab_drive_mount.log`. A missing `fusermount3` error does not require Google reauthorization.

By default, rclone mounts the actual **`MyDrive/EasyColab_Drive`** directory at `/content/drive/MyDrive`, so models reside in **`MyDrive/EasyColab_Drive/models`** on Drive. The official notebook mount instead defaults to **`MyDrive/models`**. A new OAuth app with `drive.file` does not automatically see directories created by the previous app.

If weights already exist on temporary storage, **do not release that instance yet**. Fix mounting and redeploy on the same instance, then choose **Download Weights** to copy reusable local weights into Drive. Confirm uploads have completed before releasing: rclone write caching can continue uploading after files become visible at the mountpoint.

### Reusing HF Tokens Locally

- The model panel's **HF Token** field has **Save** and **Clear** controls. Pressing Enter or starting model downloads, loading, or ComfyUI model installation also attempts to save a nonempty token. The client restores it on the next launch.
- Tokens use this Mac's **Keychain** or the current Windows user's **Credential Manager**, with entries separate from the Tunnel Token. No ordinary settings or cross-machine synchronization are used. Storage errors are reported; the token remains usable in the current session but may not be restored next time.
- Legacy Windows `settings.json` HF tokens migrate to Credential Manager, with the plaintext field atomically removed after success. Failed migration preserves the original file and pauses other settings writes to avoid losing the token or copying plaintext. Check credential permissions, then **Save** or **Clear** again.
- **Clear** deletes only EasyColab's locally stored HF Token, not the domain or Tunnel Token, and does not revoke it on Hugging Face. Rebuilding the macOS app may trigger a new Keychain permission prompt; authorize only trusted builds.

## CPU / GPU and Process Monitoring

- Sidebar CPU/GPU values show compute utilization, separate from RAM/VRAM occupancy. CPU uses `/proc/stat` deltas; GPU uses `nvidia-smi`. Disconnected, initial, or unsupported readings show `—`, not a false 0%.
- Click CPU/GPU for a **read-only** htop/nvitop-style window: PID, process name, CPU%, RSS, threads, and GPU compute-process memory/utilization. Per-process CPU is 100% per core and may exceed 100%; GPU utilization depends on driver `pmon` support and is not inferred from memory occupancy.
- `/minimax_api/processes` requires an **enabled, synchronized API key** (403 when disabled, 401 when incorrect). Utilization fields on the main status endpoint are additive. This does not expand authentication to other existing admin routes; restrict public access sources as before.
- The window fetches cached snapshots about every three seconds. Process-detail sampling starts on demand and stops about 15 seconds after closing; responses contain at most 200 processes. No command lines, environment variables, tokens, or kill controls are exposed. Disconnection clears stale details and displays a retry notice.
- The status summary updates on reconnection and completed download/load tasks, without leaving a stale disconnected warning or overwriting unrelated idle task errors. Hover for the full text, or expand/open the complete message to scroll and copy it.

---

## API Response Concurrency

- OpenAI Chat and Anthropic Messages requests with `stream=false` collect and parse generation output and count tokens in a worker thread. Waiting for inference no longer blocks the server event loop, status polling, or other SSE responses. GPU inference still uses the existing serial lock; this does not enable concurrent decoding on one GPU.
- Cancelling a request-handler task signals its generation task to stop. Deploy and restart the cloud server to activate this fix; updating local source or the desktop client does not hot-replace a running Python process. Public HTTP/2 or proxy connection failures still require separate diagnosis.

---

## Cloudflare Custom Domain (Optional)

The default remains a temporary `*.gradio.live` URL. If Cloudflare manages your domain, use a **remotely-managed named Tunnel** to give the WebUI, desktop clients, and `/v1/*` API a stable origin such as `https://ai.example.com`. DNS alone is insufficient: Colab has no stable public IP and needs a Tunnel connector.

### 1. Configure Cloudflare

1. Create a Cloudflared Tunnel under **Networking → Tunnels** (or Zero Trust → Networks → Tunnels in older dashboards).
2. Save only the **Tunnel Token** from the connector installation command, not the whole command or a Cloudflare API Token. EasyColab downloads and runs `cloudflared` on Colab; no persistent Mac service is needed.
3. Under **Routes → Add route → Published application** (formerly **Public Hostname**), add `ai.example.com` with **Service URL** `http://localhost:7860` and an **empty Path**. The dashboard creates the Tunnel DNS record; resolve any conflicting record first. Prefer a single-level subdomain; deeper subdomains may require additional certificates.
4. Do not connect independent Colab instances to the same Tunnel simultaneously: requests may be routed to different instances. Use separate tunnels/hostnames instead.

### 2. Configure EasyColab

- **macOS / Windows headless wake**: Open **Cloudflare Custom Domain**, enable it, enter `https://ai.example.com` and the Tunnel Token, then choose **Save Configuration** or **Wake & Deploy** (automatically saves first). The hostname and toggle stay in ordinary settings; the token is stored in **macOS Keychain / Windows Credential Manager** and restored on the next app launch, never written to UserDefaults, `settings.json`, or Git. Connecting to an already-running server only requires its Server URL, not a token.
- **Reuse and removal**: Tunnel tokens are reusable across Colab restarts for the same Tunnel. After rotating the token in Cloudflare, replace and save it once. Disabling the fixed-domain toggle keeps the credential. **Clear Token** removes the locally stored token while keeping the hostname; it does not revoke the Cloudflare token or interrupt an already-running tunnel.
- **System credential permissions**: Tokens are stored locally for the current OS user without enabling iCloud / cross-machine credential synchronization. macOS may request Keychain permission on first access or after rebuilding the app; authorize only your own trusted EasyColab build. Storage failure is reported and stops that custom-domain wake, with no plaintext fallback. Unsaved edits are still lost when quitting. The Windows source client cannot use Credential Manager when previewed on non-Windows systems.
- **Colab notebook**: Add `CLOUDFLARE_TUNNEL_TOKEN` in the left-hand **Secrets** panel and grant notebook access. Set `EASYCOLAB_PUBLIC_URL = "https://ai.example.com"` in step 4. Leave it blank for the random URL without reading the secret. Never paste the token into notebook source.
- **Direct Python launch**: Inject `EASYCOLAB_PUBLIC_URL` and `CLOUDFLARE_TUNNEL_TOKEN` into the process environment and run `python app.py` with `easycolab_tunnel.py` and `easycolab_vllm.py` alongside it. Keep real tokens out of command arguments, scripts, and Git.

Custom mode disables Gradio public sharing and returns the fixed URL after the connector reaches Cloudflare. Failure is explicit, with no silent fallback to a random URL. Redeploy to change settings. The hostname persists, but releasing Colab takes the service offline until redeployed using the same Tunnel. ComfyUI's independent port `8188` / temporary tunnel is unchanged.

### Security & Troubleshooting

- **A fixed hostname is not authentication.** The Tunnel Token authorizes the connector, not visitors. Existing API keys protect only the `/v1/*` gateway, **not the WebUI or `/minimax_api/*` administrative endpoints**. Before publishing, restrict the hostname in Cloudflare, for example with a WAF custom rule blocking non-trusted egress IPs. Do not expose the administration interface to untrusted networks.
- Cloudflare Access login can protect browser use. The desktop clients currently **do not support interactive Access login or Service Token headers**; browser login does not authenticate desktop requests. For desktop access, use a compatible restriction such as trusted source IPs, not an unconditional site-wide Bypass.
- Headless deployment uploads credentials through a temporary local `0600` file and deletes it after upload. Remote boot code restricts permissions, reads it, and deletes it. Tokens are not embedded in Jupyter code, command arguments, or client logs. Rotate a leaked token in Cloudflare.
- Timeout / connector exit: check the Tunnel Token and outbound connectivity to Cloudflare on port `7844`. `502`: check Service URL / server process. `404` / certificate errors: check hostname, Path, DNS, and certificate. `403` / login page: check WAF / Access rules. Connector readiness does not validate your hostname routing, DNS, or access policies.
- Failed wake now reports sanitized server/connector logs and exit codes, distinguishing process exit from the 180-second startup deadline. `Provided Tunnel token is not valid` indicates an invalid token format; authentication rejection may indicate revoked credentials; DNS/connection timeouts point to outbound connectivity. The old generic `custom tunnel failed` message means the client still bundles older resources: rebuild before redeploying. Failed deployment does not release the GPU instance; release it after troubleshooting to avoid ongoing charges.
- Cloudflare plan-dependent upload limits and request timeouts still apply; large uploads / long requests may receive `413` / `524`.

Official references: [Create a remotely-managed Tunnel](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/create-remote-tunnel/) · [Run parameters and tokens](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/configure-tunnels/run-parameters/).

### Open WebUI / Magpie Streaming Disconnects

`EasyColab: connection lost mid-reply (http2: client connection lost)` is a relay-client HTTP/2 transport error, not model output or a model-list error. For Open WebUI → Magpie → Cloudflare → EasyColab, inspect Magpie's logs as well as Colab's GPU. Go emits this error when an HTTP/2 PING health check fails, interrupting requests on the shared connection. The message alone cannot identify whether a local proxy, packet loss or an edge node caused the missing response. Cloudflare `524` and BIC `1010` are separate issues.

- **Use HTTP/1.1 for this provider**: Magpie → EasyColab → Advanced → HTTP version → HTTP/1.1 only → Save. Keep HTTPS, certificate validation and API-key authentication enabled. Do not disable HTTP/2 zone-wide or turn off certificate checks. This avoids HTTP/2 health-check/shared-connection failure modes, not every network outage.
- **Server heartbeats**: while waiting for output, OpenAI streams emit an SSE `: keep-alive` comment every five seconds; Anthropic streams emit a `ping` event. This also covers queueing, prefill and tool-call assembly. Heartbeats do not contribute text or tokens. Responses use `Cache-Control: no-cache, no-transform` and `X-Accel-Buffering: no`, without the hop-by-hop `Connection` header prohibited by HTTP/2. An additional Nginx proxy must still disable response buffering for API routes and use an appropriate read timeout.
- **Failures are not success**: generation failures emit `upstream_generation_error` without a successful `stop`, `[DONE]` or `message_stop`. A disconnected client promptly signals cancellation and allows waiting iterators to exit. Partially delivered requests are never automatically replayed, avoiding duplicated answers or tool side effects.
- **Request correlation**: match the response's `X-Request-ID` with `request_id` in Colab's `[API stream]` logs. Terminal states are `completed`, `disconnected` or `error`, with duration, frame/heartbeat counts and exception type, never prompts, full answers or credentials. `completed` means the origin finished emitting, not that every intermediary delivered everything to the client.
- **Non-streaming tasks differ**: Open WebUI's title, tag or search-suggestion tasks may send `stream:false` and contend with conversation requests for the serialized GPU. SSE heartbeats cannot keep an ordinary JSON response alive. Review auxiliary-task model selection, output limits and thinking settings; use a faster task model where appropriate. Raising only Open WebUI's client timeout cannot override Cloudflare's origin timeout.

Redeploy the bundled server resources to activate server changes. Changing Magpie's HTTP/1.1 setting alone does not restart Colab. For remaining failures, record client time, request ID, HTTP status and the matching Colab terminal state, never API keys.

Local verification on 2026-11-10: after enabling this provider's HTTP/1.1 option, both a short request and an 854-output-token request through Magpie reached `[DONE]`; this is not a long-term stability guarantee. New server behavior passed isolated OpenAI/Anthropic regressions and real TCP heartbeat/disconnect tests. The running GPU service was not hot-patched or restarted; public-path heartbeat verification requires redeployment.

References: [SSE heartbeats and message format](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events), [Magpie per-provider HTTP/1.1](https://github.com/yetone/magpie/blob/v0.1.3351/internal/netproxy/http1.go), [HTTP/2 health checks](https://github.com/yetone/magpie/blob/v0.1.3351/internal/netproxy/netproxy.go).

---

## Privacy & Security Best Practices

1. **Screen-Recording / Screenshot Redaction Mode**: Next to the **Server URL** input in the left sidebar, toggle **Redact / Mask Mode** (eye icon on macOS, **Mask** button on Windows). This masks server/custom-domain fields, URL hostnames in runtime logs, and your Google account email. Redaction is not access control.
2. **Keep API Key Authentication Enabled**: When exposing the Qwen API Gateway to external tools, keep **Enable API Key Auth** turned on.
3. **Local Credentials & Data Locations**:
   - Google OAuth tokens are stored strictly on your local machine at `~/.config/colab-cli/token.json` (`%USERPROFILE%\.config\colab-cli\token.json` on Windows) and are never uploaded to any third-party server.
   - Windows client settings are stored at `%LOCALAPPDATA%\EasyColab\settings.json`, and generated media is saved by default to `%USERPROFILE%\Videos\EasyColab` (`~/Movies/EasyColab` on macOS).

---

## Disclaimer & Compliance

- **Unofficial Independent Project**: EasyColab is an independent, community-developed open-source client and companion toolkit. **It is not affiliated with, endorsed by, or sponsored by Google LLC, Google Colab, MiniMax, Alibaba Qwen, or any of their affiliates.**
- **Platform Terms of Service (ToS) Notice**:
  - The headless *"One-Click Wake & Deploy"* feature interacts with your own Paid Compute Units via the open-source community library [`google-colab-cli`](https://pypi.org/project/google-colab-cli/). **It is strongly recommended solely for reasonable personal use on accounts with an active Colab Pro / Pro+ / Google AI Ultra subscription.**
  - Do not abuse headless background connections on the Google Colab Free Tier, and never use it for cryptocurrency mining, multi-account farming, or unauthorized compute reselling. Connecting third-party clients to cloud runtimes may be subject to platform policy changes; users assume full responsibility for evaluating and bearing any account-related risks. For a 100% official browser-based workflow, use the bundled `EasyColab_Server.ipynb`.
- **Model & Upstream Component Licenses**:
  - This repository **does not include or distribute any model weights or GPL source code**. All model weights are downloaded directly by the user at runtime from official Hugging Face repositories and remain subject to their respective upstream licenses (e.g., *MiniMax-H3 Community License Agreement*, *Apache-2.0*, *Tongyi Qianwen License*, etc.).
  - The cloud ComfyUI Studio clones the official repository on demand inside the user's personal cloud VM and communicates over an out-of-process HTTP API; ComfyUI itself is licensed under **GPL-3.0**.

---

## Acknowledgements

Special thanks to the following open-source projects and model teams:
- [DiffSynth-Studio](https://github.com/modelscope/DiffSynth-Studio)
- [ComfyUI](https://github.com/comfyanonymous/ComfyUI) & [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager)
- [MiniMax-H3](https://github.com/MiniMax-AI/MiniMax-H3)
- [Qwen](https://github.com/QwenLM) & [Unsloth](https://github.com/unslothai/unsloth)
- [llama.cpp](https://github.com/ggml-org/llama.cpp)
- [google-colab-cli](https://pypi.org/project/google-colab-cli/)

---

## License

The source code of this project is released under the [Apache License 2.0](./LICENSE).
