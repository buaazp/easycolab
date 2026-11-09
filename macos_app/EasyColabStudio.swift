import SwiftUI
import AVKit
import AppKit
import UniformTypeIdentifiers
import ObjectiveC.runtime

// MARK: - 中英文国际化语言管理 (默认简体中文 "zh")

enum AppLanguage: String, CaseIterable {
    case zh = "zh"
    case en = "en"
}

extension Notification.Name {
    static let easyColabLanguageDidChange = Notification.Name("EasyColab.LanguageDidChange")
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var lang: AppLanguage {
        didSet {
            UserDefaults.standard.set(lang.rawValue, forKey: "appLanguage")
            if oldValue != lang {
                NotificationCenter.default.post(name: .easyColabLanguageDidChange, object: nil)
            }
        }
    }

    var isEN: Bool { lang == .en }

    private init() {
        if UserDefaults.standard.string(forKey: "appLanguage") == "en" {
            self.lang = .en
        } else {
            self.lang = .zh
        }
    }

    func toggle() {
        lang = (lang == .zh) ? .en : .zh
    }
}

@inline(__always)
func L(_ zh: String, _ en: String) -> String {
    LanguageManager.shared.lang == .en ? en : zh
}

func localizeModelFileDesc(_ raw: String) -> String {
    guard LanguageManager.shared.isEN, !raw.isEmpty else { return raw }
    var s = raw
    s = s.replacingOccurrences(of: " [RAM内存盘]", with: " [RAM Disk]")
    s = s.replacingOccurrences(of: "DiT 音视频主干 BF16", with: "DiT Audio-Video Backbone BF16")
    s = s.replacingOccurrences(of: "多模态编码器 BF16", with: "Multimodal Encoder BF16")
    s = s.replacingOccurrences(of: "3D 视频 VAE BF16", with: "3D Video VAE BF16")
    s = s.replacingOccurrences(of: "32kHz 立体声 VAE BF16", with: "32kHz Stereo Audio VAE BF16")
    s = s.replacingOccurrences(of: "权重分片", with: "Weight Shard")
    s = s.replacingOccurrences(of: "Unsloth UD-Q4_K_M 主模型", with: "Unsloth UD-Q4_K_M Main Model")
    s = s.replacingOccurrences(of: "多模态视觉投影器", with: "Multimodal Vision Projector")
    s = s.replacingOccurrences(of: "Unsloth MTP 多词元投机解码头", with: "Unsloth MTP Speculative Decoding Head")
    s = s.replacingOccurrences(of: "编码器", with: "Encoder")
    s = s.replacingOccurrences(of: "图像 VAE", with: "Image VAE")
    return s
}

func localizeServerText(_ text: String) -> String {
    guard LanguageManager.shared.isEN, !text.isEmpty else { return text }

    let exactMap: [String: String] = [
        "未加载": "Not Loaded",
        "未连接 Colab 服务端": "Colab Server Disconnected",
        "尚未启动云端 ComfyUI 工作台": "Cloud ComfyUI Studio Not Started",
        "尚未启动（支持一键拉起 ComfyUI + Google Drive 自动软链持久化）": "Not started (1-click ComfyUI + Google Drive auto-symlink persistence ready)",
        "Google Drive 自动软链持久化": "Google Drive Auto-Symlink Persistence",
        "Google Drive 实时软链挂载": "Google Drive Live Symlink Mount",
        "Google Drive 云盘自动持久化": "Google Drive Auto-Persistence",
        "实例本地高速存储": "Instance Local NVMe Storage",
        "就绪：默认已选 G4 (RTX PRO 6000 · 96GB)，可在左侧一键唤醒实例并部署模型。": "Ready: G4 (RTX PRO 6000 · 96GB) selected by default. Wake & deploy from the left sidebar.",
        "已彻底释放全部云端实例，计费速率归零。": "All cloud Colab instances terminated. Billing rate is now 0 CU/h.",
        "正在初始化 ComfyUI 环境与 Google Drive 持久化目录...": "Initializing ComfyUI environment & Google Drive persistence folders...",
        "正在释放现有常驻模型显存，为 ComfyUI 腾出完整 96GB 空间...": "Releasing resident models from VRAM to free full 96GB for ComfyUI...",
        "正在从 Google Drive 恢复历史持久化的 ComfyUI 节点、模型与工作流...": "Restoring persisted ComfyUI nodes, models & workflows from Google Drive...",
        "正在克隆官方最新 ComfyUI 核心引擎...": "Cloning latest official ComfyUI core engine...",
        "正在安装 ComfyUI 核心依赖（保留当前 G4 Blackwell CUDA PyTorch）...": "Installing ComfyUI core dependencies (preserving G4 Blackwell CUDA PyTorch)...",
        "正在恢复已持久化的自定义节点并配置 ComfyUI-Manager...": "Restoring persisted custom nodes & configuring ComfyUI-Manager...",
        "正在检查并安装已保存自定义节点的 Python 依赖包...": "Checking & installing Python packages for saved custom nodes...",
        "正在拉起 ComfyUI 节点推理引擎 (端口 8188)...": "Starting ComfyUI node inference engine (Port 8188)...",
        "ComfyUI 内核已就绪，正在建立 Cloudflare 高速全屏画布隧道...": "ComfyUI engine ready. Opening Cloudflare Quick Tunnel for fullscreen canvas...",
        "ComfyUI 已停止（节点、模型与工作流已持久化保存至 Google Drive）": "ComfyUI stopped (nodes, models & workflows persisted to Google Drive)",
        "正在先从 Google Drive 检查已持久化的历史模型权重...": "Checking Google Drive for previously persisted model weights...",
        "正在将配齐的模型与中文工作流持久化同步至 Google Drive...": "Syncing installed models & workflow templates to Google Drive...",
        "正在预装并校验 llama.cpp CUDA 高速推理引擎...": "Installing & verifying llama.cpp CUDA inference engine...",
        "正在映射 MiniMax-H3 BF16 多模态编码器权重 (14 分片)...": "Mapping MiniMax-H3 BF16 multimodal encoder weights (14 shards)...",
        "正在映射 MiniMax-H3 BF16 33B DiT 主干权重 (13 分片)...": "Mapping MiniMax-H3 BF16 33B DiT backbone weights (13 shards)...",
        "正在映射 3D 视频 VAE 与 32kHz 立体声 VAE 权重...": "Mapping 3D Video VAE & 32kHz Stereo Audio VAE weights...",
        "正在构建 MiniMax-H3 BF16 原生 GPU 计算图与 Processor...": "Building MiniMax-H3 native BF16 GPU computation graph & processor...",
        "正在映射 Qwen-Image-2.1 权重并构建 GPU 管线...": "Mapping Qwen-Image-2.1 weights & building GPU pipeline...",
        "正在映射 Z-Image-Turbo 权重并构建 8 步极速生图管线...": "Mapping Z-Image-Turbo weights & building 8-step turbo pipeline...",
        "正在预热 Qwen3.8-27B-UD-Q4_K_M.gguf 与 mmproj 视觉权重...": "Warming up Qwen3.8-27B-UD-Q4_K_M.gguf & mmproj vision weights...",
        "正在自动补齐 Unsloth MTP 投机解码加速头 (1.31 GB)...": "Downloading Unsloth MTP speculative decoding head (1.31 GB)...",
        "正在上传最新多模型开源服务端代码 (app.py)...": "Uploading latest multi-model server engine (app.py)...",
        "正在云端配置 Google Drive 持久化、多模型引擎并启动隧道 (约需 40~90 秒)...": "Configuring Google Drive persistence, multi-model engine & public tunnel (~40–90s)...",
        "正在克隆 DiffSynth-Studio...": "Cloning DiffSynth-Studio...",
        "容器仍在初始化，继续尝试连接内核...": "Container still initializing, retrying kernel connection...",
        "旧实例已失效或正在销毁，正在自动清理并重新分配新实例...": "Previous runtime expired; cleaning up and provisioning a fresh GPU instance...",
        "已手动停止当前推理任务": "Inference cancelled by user",
        "首尾帧模式下请至少提供首帧或尾帧图片": "Please provide at least a start frame or end frame image in First/Last Frame mode",
        "图像编辑/重绘模式下请至少拖入一张输入图片": "Please drop at least one reference image in Image Edit / Restyle mode"
    ]
    if let exact = exactMap[text] {
        return exact
    }

    var s = localizeModelFileDesc(text)
    let replacements: [(String, String)] = [
        ("已无缝接管在线 ComfyUI 画布", "Connected to active ComfyUI canvas"),
        ("ComfyUI 进程已退出", "ComfyUI process exited"),
        ("，可点击重新启动", "; click to restart"),
        ("正在建立 ", "Linking "),
        (" 目录软链", " symlinks"),
        ("正在准备配齐「", "Preparing preset pack \""),
        ("正在生成「", "Generating workflow templates for \""),
        ("」全中文三步傻瓜注释工作流...", "\"..."),
        ("」（共 ", "\" ("),
        (" 个官方权重）...", " official weights)..."),
        ("正在 8 线程极速下载 ", "8-thread fast downloading "),
        ("正在 8 线程并发下载 ", "8-thread downloading "),
        ("正在下载 ", "Downloading "),
        (" 至 models/", " to models/"),
        (" 已就绪 (", " ready ("),
        (")，跳过下载", "), skipping"),
        ("正在为 ", "Starting 8-stream parallel download for "),
        (" 启动 8 路并发 HTTP Range 极速下载通道...", "..."),
        ("正在获取 ", "Fetching tokenizer & processor configs for "),
        (" 的分词器与 Processor 配置文件...", "..."),
        ("正在评估显存余量并装载 ", "Checking VRAM & loading "),
        (" 至 GPU...", " into GPU..."),
        ("[显存常驻加速] 正在将子模块 ", "[VRAM Pinning] Warming up submodule "),
        (" 预热锁入 GPU 显存...", " in GPU VRAM..."),
        (" 正在编码多模态上下文并启动推理...", " encoding multimodal context & starting inference..."),
        (" 推理完成！耗时 ", " inference complete! Elapsed "),
        (" 正在使用多模态编码器解析提示词", " encoding prompts with multimodal encoder"),
        ("DiT 采样已完成，正在执行", "DiT sampling finished, running "),
        ("3D 视频 VAE 解码", "3D Video VAE decoding"),
        ("视频帧解码完成，正在执行 32kHz 立体声音轨解码", "Video frames decoded, decoding 32kHz stereo audio"),
        (" 正在执行去噪采样第 ", " denoising step "),
        (" 步 (", " ("),
        ("VAE 解码完成，正在合成 32kHz 立体声音轨并封装 MP4", "VAE decoded, muxing 32kHz stereo audio into MP4"),
        ("正在写入无损 PNG 图像文件", "Writing lossless PNG image"),
        ("正在等待上一任务释放 GPU 显存锁...", "Waiting for previous job to release GPU lock..."),
        ("生成完成！耗时 ", "Generation complete! Elapsed "),
        ("生成出错: ", "Generation error: "),
        ("尚未加载至 Colab GPU 显存，请先在 Mac 客户端点击「加载到显存」。", "is not loaded in Colab GPU VRAM. Click 'Load to VRAM' in the Mac app first."),
        ("尚未加载到 GPU 显存！请先在左侧点击「加载到显存」（显存充裕时可与现有模型同时常驻）。", "is not loaded in GPU VRAM! Click 'Load to VRAM' on the left first (can co-reside with loaded models)."),
        ("尚未加载至 GPU 显存！请先在左侧点击「加载到显存」。", "is not loaded in GPU VRAM! Click 'Load to VRAM' on the left first."),
        ("尚未加载到显存", "is not loaded in VRAM"),
        ("当前已常驻：", "currently resident: "),
        ("请点击左侧「加载到显存」，显存充裕时可同时常驻无需卸载现有模型。", "Click 'Load to VRAM' on the left (can co-reside when VRAM permits)."),
        ("当前已分配实例型号为 ", "Current assigned instance is "),
        ("，正在释放并切换为您选择的 ", "; releasing and switching to "),
        ("正在检查已有实例 ", "Checking existing runtime "),
        (" 连通性...", " connectivity..."),
        ("已通过 Google OAuth 自动挂载 Google Drive", "Mounted Google Drive automatically via Google OAuth"),
        ("启动超时，日志尾部: ", "Startup timed out, log tail: "),
        ("Google Drive 实时软链挂载", "Google Drive Live Symlink"),
        ("Google Drive 云盘自动持久化", "Google Drive Auto-Persist"),
        ("实例本地高速存储", "Local NVMe Storage")
    ]
    for (zhSub, enSub) in replacements {
        if s.contains(zhSub) {
            s = s.replacingOccurrences(of: zhSub, with: enSub)
        }
    }
    return s
}

func localizeConsoleLine(_ line: String) -> String {
    guard LanguageManager.shared.isEN, !line.isEmpty else { return line }
    if line.contains("实时下载/采样进度流") {
        return line.replacingOccurrences(of: "实时下载/采样进度流", with: "Live Download / Sampling Progress")
    }
    return localizeServerText(line)
}

// MARK: - 多模型与多模态数据结构

enum ModelModality: String, Codable {
    case videoAudio = "video_audio"
    case video = "video"
    case image = "image"
    case llmVLM = "llm_vlm"
    case comfyUI = "comfyui"
}

struct TaskModeItem: Identifiable, Hashable {
    let id: String
    let titleZh: String
    let titleEn: String
    let subtitleZh: String
    let subtitleEn: String
    let icon: String

    var title: String { L(titleZh, titleEn) }
    var subtitle: String { L(subtitleZh, subtitleEn) }

    static func == (lhs: TaskModeItem, rhs: TaskModeItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct OpenModelSpec: Identifiable, Hashable {
    let id: String
    let nameZh: String
    let nameEn: String
    let repoId: String
    let badgeZh: String
    let badgeEn: String
    let summaryZh: String
    let summaryEn: String
    let approxSizeGB: Double
    let icon: String
    let modality: ModelModality
    let defaultSteps: Double
    let modes: [TaskModeItem]
    let defaultFiles: [ModelFileItem]

    var name: String { L(nameZh, nameEn) }
    var badge: String { L(badgeZh, badgeEn) }
    var summary: String { L(summaryZh, summaryEn) }

    static func == (lhs: OpenModelSpec, rhs: OpenModelSpec) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ModelFileItem: Codable, Identifiable, Hashable {
    var id: String { name }
    var name: String
    var desc: String?
    var exists: Bool
    var size_gb: Double

    var localizedDesc: String? {
        guard let raw = desc, !raw.isEmpty else { return nil }
        return localizeModelFileDesc(raw)
    }
}

let OPEN_MODEL_CATALOG: [OpenModelSpec] = [
    OpenModelSpec(
        id: "minimax_h3",
        nameZh: "MiniMax-H3 (33B)",
        nameEn: "MiniMax-H3 (33B)",
        repoId: "MiniMaxAI/MiniMax-H3",
        badgeZh: "BF16 原生 · 134 GB",
        badgeEn: "Native BF16 · 134 GB",
        summaryZh: "全模态 BF16 原生满血精度同步生成高清视频与 32kHz 立体声音效、人声对白及配乐",
        summaryEn: "Full-modality native BF16 generation of HD video with synchronized 32kHz stereo SFX, dialogue & music",
        approxSizeGB: 134.1,
        icon: "film.stack",
        modality: .videoAudio,
        defaultSteps: 35,
        modes: [
            TaskModeItem(
                id: "t2va",
                titleZh: "文生音视频",
                titleEn: "Text to Video+Audio",
                subtitleZh: "输入镜头与声音描述，同步生成视频与立体声音轨",
                subtitleEn: "Generate HD video and synchronized stereo audio from scene & sound prompts",
                icon: "film"
            ),
            TaskModeItem(
                id: "fl2va",
                titleZh: "首尾帧生视频",
                titleEn: "First/Last Frame to Video",
                subtitleZh: "上传首帧或尾帧参考图，精准控制起止画面与运镜过渡",
                subtitleEn: "Upload start or end keyframes to lock composition and camera transitions",
                icon: "photo.on.rectangle.angled"
            )
        ],
        defaultFiles: (1...13).map { i in
            ModelFileItem(
                name: String(format: "FL2VA/transformer/model-%05d-of-00013.safetensors", i),
                desc: "DiT 音视频主干 BF16 \(i)/13",
                exists: false,
                size_gb: 0
            )
        } + (1...14).map { i in
            ModelFileItem(
                name: String(format: "FL2VA/text_encoder/model-%05d-of-00014.safetensors", i),
                desc: "多模态编码器 BF16 \(i)/14",
                exists: false,
                size_gb: 0
            )
        } + [
            ModelFileItem(name: "FL2VA/video_vae/source/model.safetensors", desc: "3D 视频 VAE BF16 (9.7 GB)", exists: false, size_gb: 0),
            ModelFileItem(name: "FL2VA/audio_vae/model.safetensors", desc: "32kHz 立体声 VAE BF16 (0.6 GB)", exists: false, size_gb: 0)
        ]
    ),
    OpenModelSpec(
        id: "comfyui_studio",
        nameZh: "ComfyUI 节点工作台",
        nameEn: "ComfyUI Node Studio",
        repoId: "comfyanonymous/ComfyUI",
        badgeZh: "节点视频创作 · 云盘软链持久化",
        badgeEn: "Node Video Studio · Drive Symlink Persist",
        summaryZh: "一键拉起云端 ComfyUI + Manager 全屏节点画布，自定义节点、视频权重与工作流自动软链持久化至 Google Drive",
        summaryEn: "1-click cloud ComfyUI + Manager fullscreen node canvas with Google Drive symlink persistence for custom nodes, weights & workflows",
        approxSizeGB: 0.0,
        icon: "point.3.connected.trianglepath.dotted",
        modality: .comfyUI,
        defaultSteps: 25,
        modes: [
            TaskModeItem(
                id: "comfy_canvas",
                titleZh: "全屏节点画布",
                titleEn: "Fullscreen Node Canvas",
                subtitleZh: "一键部署并跳转浏览器全屏节点画布，复用 G4 保活、折线监控与自动休眠",
                subtitleEn: "Deploy & open fullscreen canvas in browser with G4 keepalive, live telemetry & auto-sleep",
                icon: "macwindow.badge.plus"
            ),
            TaskModeItem(
                id: "comfy_assets",
                titleZh: "极速下权重与回传成片",
                titleEn: "Fast Weights & Pull Outputs",
                subtitleZh: "8 线程极速下载视频模型至云盘 models 目录，并将 output 成片一键回传 Mac",
                subtitleEn: "8-thread fast model download to Drive models folder & 1-click output pull to Mac",
                icon: "externaldrive.badge.icloud"
            )
        ],
        defaultFiles: []
    ),
    OpenModelSpec(
        id: "qwen38_27b",
        nameZh: "Qwen3.8-27B",
        nameEn: "Qwen3.8-27B",
        repoId: "Qwen/Qwen3.8-27B",
        badgeZh: "BF16 原生 · 51.8 GB",
        badgeEn: "Native BF16 · 51.8 GB",
        summaryZh: "Hugging Face 榜首开源多模态大模型（BF16 原生满血精度，支持最高 256K 上下文，需大显存实例）",
        summaryEn: "Top Hugging Face open multimodal LLM (full native BF16 precision, up to 256K context, high-VRAM GPU)",
        approxSizeGB: 51.8,
        icon: "brain",
        modality: .llmVLM,
        defaultSteps: 20,
        modes: [
            TaskModeItem(
                id: "chat",
                titleZh: "深度推理对话",
                titleEn: "Deep Reasoning Chat",
                subtitleZh: "支持长思维链推理、代码架构、复杂逻辑与分镜脚本创作",
                subtitleEn: "Long chain-of-thought reasoning, software architecture, logic & storyboard scripting",
                icon: "bubble.left.and.bubble.right"
            ),
            TaskModeItem(
                id: "vlm",
                titleZh: "图像视觉理解",
                titleEn: "Vision Understanding",
                subtitleZh: "拖入图片进行画面解析、OCR 识别或反推专业生图/生视频提示词",
                subtitleEn: "Drop images for scene analysis, OCR, or reverse-engineering image/video prompts",
                icon: "eye"
            ),
            TaskModeItem(
                id: "api",
                titleZh: "API 协议网关",
                titleEn: "API Protocol Gateway",
                subtitleZh: "提供 OpenAI (/v1) 与 Anthropic (/v1/messages) 双协议公网接口",
                subtitleEn: "Public dual-protocol gateway compatible with OpenAI (/v1) & Anthropic (/v1/messages)",
                icon: "network"
            )
        ],
        defaultFiles: (1...18).map { i in
            ModelFileItem(
                name: String(format: "model-%05d-of-00018.safetensors", i),
                desc: "权重分片 \(i)/18",
                exists: false,
                size_gb: 0
            )
        }
    ),
    OpenModelSpec(
        id: "qwen38_27b_gguf",
        nameZh: "Qwen3.8-27B-GGUF",
        nameEn: "Qwen3.8-27B-GGUF",
        repoId: "unsloth/Qwen3.8-27B-GGUF",
        badgeZh: "UD-Q4_K_M + MTP · 18.7 GB",
        badgeEn: "UD-Q4_K_M + MTP · 18.7 GB",
        summaryZh: "Unsloth 动态 4-bit 量化 + 原生 MTP 多词元投机解码加速，支持最高 256K 上下文与多模态视觉理解",
        summaryEn: "Unsloth dynamic 4-bit quantization + native MTP speculative decoding (~100 tok/s), up to 256K context & vision",
        approxSizeGB: 18.7,
        icon: "cpu",
        modality: .llmVLM,
        defaultSteps: 20,
        modes: [
            TaskModeItem(
                id: "chat",
                titleZh: "深度推理对话",
                titleEn: "Deep Reasoning Chat",
                subtitleZh: "UD-Q4_K_M + MTP 投机解码极速推理，支持长思维链、代码架构与超长上下文分析",
                subtitleEn: "Ultra-fast UD-Q4_K_M + MTP speculative decoding for CoT reasoning, coding & long-context analysis",
                icon: "bubble.left.and.bubble.right"
            ),
            TaskModeItem(
                id: "vlm",
                titleZh: "图像视觉理解",
                titleEn: "Vision Understanding",
                subtitleZh: "内置 mmproj-F16 视觉投影器，支持图片解析、OCR 与生图/生视频提示词反推",
                subtitleEn: "Built-in mmproj-F16 vision projector for image analysis, OCR & prompt reverse-engineering",
                icon: "eye"
            ),
            TaskModeItem(
                id: "api",
                titleZh: "API 协议网关",
                titleEn: "API Protocol Gateway",
                subtitleZh: "提供 OpenAI (/v1) 与 Anthropic (/v1/messages) 双协议公网接口",
                subtitleEn: "Public dual-protocol gateway compatible with OpenAI (/v1) & Anthropic (/v1/messages)",
                icon: "network"
            )
        ],
        defaultFiles: [
            ModelFileItem(name: "Qwen3.8-27B-UD-Q4_K_M.gguf", desc: "Unsloth UD-Q4_K_M 主模型 (16.5 GB)", exists: false, size_gb: 0),
            ModelFileItem(name: "mmproj-F16.gguf", desc: "多模态视觉投影器 (0.93 GB)", exists: false, size_gb: 0),
            ModelFileItem(name: "MTP/mtp-Qwen3.8-27B-Q4_0.gguf", desc: "Unsloth MTP 多词元投机解码头 (1.31 GB)", exists: false, size_gb: 0)
        ]
    ),
    OpenModelSpec(
        id: "deepseek_v4_pro_qwen35_9b_heretic",
        nameZh: "DeepSeek-V4-Pro-Qwen3.5-9B-UNCENSORED-heretic",
        nameEn: "DeepSeek-V4-Pro-Qwen3.5-9B-UNCENSORED-heretic",
        repoId: "xtools-at/DeepSeek-V4-Pro-Qwen3.5-9B-UNCENSORED-heretic",
        badgeZh: "BF16 原生 · 18 GB",
        badgeEn: "Native BF16 · 18 GB",
        summaryZh: "基于 Qwen3.5-9B 的 DeepSeek-V4-Pro 蒸馏推理模型（Heretic 版本），支持最高 256K 上下文",
        summaryEn: "DeepSeek-V4-Pro reasoning distillation based on Qwen3.5-9B (Heretic variant), up to 256K context",
        approxSizeGB: 18.0,
        icon: "brain",
        modality: .llmVLM,
        defaultSteps: 20,
        modes: [
            TaskModeItem(
                id: "chat",
                titleZh: "深度推理对话",
                titleEn: "Deep Reasoning Chat",
                subtitleZh: "支持数学、科学与多轮推理对话",
                subtitleEn: "Mathematics, science & multi-turn reasoning chat",
                icon: "bubble.left.and.bubble.right"
            ),
            TaskModeItem(
                id: "vlm",
                titleZh: "图像视觉理解",
                titleEn: "Vision Understanding",
                subtitleZh: "使用 Qwen3.5 视觉编码器进行图片理解",
                subtitleEn: "Image understanding with the Qwen3.5 vision encoder",
                icon: "eye"
            ),
            TaskModeItem(
                id: "api",
                titleZh: "API 协议网关",
                titleEn: "API Protocol Gateway",
                subtitleZh: "提供 OpenAI (/v1) 与 Anthropic (/v1/messages) 双协议公网接口",
                subtitleEn: "Public dual-protocol gateway compatible with OpenAI (/v1) & Anthropic (/v1/messages)",
                icon: "network"
            )
        ],
        defaultFiles: (1...4).map { shard in
            ModelFileItem(
                name: String(format: "model-%05d-of-00004.safetensors", shard),
                desc: "权重分片 \(shard)/4",
                exists: false,
                size_gb: 0
            )
        } + [
            ModelFileItem(name: "model-mtp.safetensors", desc: "MTP 权重（模型索引必需文件）", exists: false, size_gb: 0)
        ]
    ),
    OpenModelSpec(
        id: "qwen38_flash_next_nvfp4",
        nameZh: "Qwen3.8-Flash-Next-Uncensored-NVFP4",
        nameEn: "Qwen3.8-Flash-Next-Uncensored-NVFP4",
        repoId: "orcarouter/Qwen3.8-Flash-Next-Uncensored-NVFP4",
        badgeZh: "单卡 96GB · PLE→CPU · 171 GiB",
        badgeEn: "Single 96GB GPU · PLE→CPU · 171 GiB",
        summaryZh: "需 HF 授权、Blackwell 96GB 与至少 112 GiB 可用系统内存；独立 vLLM、4K–32K 上下文，默认关闭 MTP",
        summaryEn: "Requires HF access, Blackwell 96GB & 112 GiB free RAM; isolated vLLM, 4K–32K context, MTP off",
        approxSizeGB: 170.9,
        icon: "brain",
        modality: .llmVLM,
        defaultSteps: 20,
        modes: [
            TaskModeItem(id: "chat", titleZh: "深度推理对话", titleEn: "Reasoning Chat",
                         subtitleZh: "NVFP4 专家驻留 GPU，PLE 表使用 CPU 内存", subtitleEn: "NVFP4 experts on GPU, PLE table in host RAM", icon: "bubble.left.and.bubble.right"),
            TaskModeItem(id: "vlm", titleZh: "图像视觉理解", titleEn: "Vision Understanding",
                         subtitleZh: "保留原始视觉塔，看图占用额外显存", subtitleEn: "Original vision tower; images need extra VRAM", icon: "eye"),
            TaskModeItem(id: "api", titleZh: "API 协议网关", titleEn: "API Gateway",
                         subtitleZh: "OpenAI / Anthropic 协议、工具调用与思考模式", subtitleEn: "OpenAI / Anthropic protocols, tools & reasoning", icon: "network")
        ],
        defaultFiles: (1...17).map { shard in
            ModelFileItem(name: String(format: "model-%05d-of-00017.safetensors", shard),
                          desc: "NVFP4 混合精度分片 \(shard)/17", exists: false, size_gb: 0)
        } + [ModelFileItem(name: "model-mtp.safetensors", desc: "MTP 权重（不默认启用投机解码）", exists: false, size_gb: 0)]
    ),
    OpenModelSpec(
        id: "qwen_image_21",
        nameZh: "Qwen-Image-2.1",
        nameEn: "Qwen-Image-2.1",
        repoId: "Qwen/Qwen-Image-2.1",
        badgeZh: "文生图与修图 · 30.9 GB",
        badgeEn: "Text-to-Image & Edit · 30.9 GB",
        summaryZh: "通义千问新一代旗舰图像生成与自然语言多图指令编辑模型",
        summaryEn: "Qwen flagship image generation & natural-language multi-image instruction editing model",
        approxSizeGB: 30.9,
        icon: "paintbrush.pointed",
        modality: .image,
        defaultSteps: 40,
        modes: [
            TaskModeItem(
                id: "t2i",
                titleZh: "高清文生图",
                titleEn: "HD Text-to-Image",
                subtitleZh: "复杂构图、精准中英文排版与高质感摄影/插画生成",
                subtitleEn: "Complex composition, accurate bilingual typography & high-fidelity photography/illustration",
                icon: "photo.artframe"
            ),
            TaskModeItem(
                id: "i2i_edit",
                titleZh: "多图指令修图",
                titleEn: "Multi-Image Instruction Edit",
                subtitleZh: "上传 1~2 张原图，用自然语言指令改局部、换背景或融合主体",
                subtitleEn: "Upload 1–2 source images to edit regions, swap backgrounds, or fuse subjects via natural language",
                icon: "wand.and.rays"
            )
        ],
        defaultFiles: [
            ModelFileItem(name: "transformer/diffusion_pytorch_model-00001-of-00002.safetensors", desc: "DiT 1/2", exists: false, size_gb: 0),
            ModelFileItem(name: "transformer/diffusion_pytorch_model-00002-of-00002.safetensors", desc: "DiT 2/2", exists: false, size_gb: 0),
            ModelFileItem(name: "text_encoder/model-00001-of-00004.safetensors", desc: "编码器 1/4", exists: false, size_gb: 0),
            ModelFileItem(name: "text_encoder/model-00002-of-00004.safetensors", desc: "编码器 2/4", exists: false, size_gb: 0),
            ModelFileItem(name: "text_encoder/model-00003-of-00004.safetensors", desc: "编码器 3/4", exists: false, size_gb: 0),
            ModelFileItem(name: "text_encoder/model-00004-of-00004.safetensors", desc: "编码器 4/4", exists: false, size_gb: 0),
            ModelFileItem(name: "vae/diffusion_pytorch_model.safetensors", desc: "图像 VAE", exists: false, size_gb: 0)
        ]
    ),
    OpenModelSpec(
        id: "z_image_turbo",
        nameZh: "Z-Image-Turbo",
        nameEn: "Z-Image-Turbo",
        repoId: "Tongyi-MAI/Z-Image-Turbo",
        badgeZh: "8步极速生图 · 30.6 GB",
        badgeEn: "8-Step Turbo Image · 30.6 GB",
        summaryZh: "Hugging Face 高人气 8 步蒸馏极速写实摄影与中英文海报生图模型",
        summaryEn: "Popular Hugging Face 8-step distilled model for ultra-fast photorealism & bilingual poster design",
        approxSizeGB: 30.6,
        icon: "bolt.square",
        modality: .image,
        defaultSteps: 8,
        modes: [
            TaskModeItem(
                id: "t2i",
                titleZh: "8 步极速文生图",
                titleEn: "8-Step Fast Text-to-Image",
                subtitleZh: "仅需 8 步采样，秒级输出商业级人像摄影与中英文排版画面",
                subtitleEn: "Commercial-grade portrait photography & bilingual poster typography in just 8 steps",
                icon: "bolt"
            ),
            TaskModeItem(
                id: "i2i_edit",
                titleZh: "图生图风格重绘",
                titleEn: "Image-to-Image Restyle",
                subtitleZh: "上传参考底图并调节重绘幅度，保留构图生成全新细节",
                subtitleEn: "Upload a reference image and adjust denoising strength to restyle while preserving layout",
                icon: "square.on.square"
            )
        ],
        defaultFiles: [
            ModelFileItem(name: "transformer/diffusion_pytorch_model-00001-of-00003.safetensors", desc: "DiT 1/3", exists: false, size_gb: 0),
            ModelFileItem(name: "transformer/diffusion_pytorch_model-00002-of-00003.safetensors", desc: "DiT 2/3", exists: false, size_gb: 0),
            ModelFileItem(name: "transformer/diffusion_pytorch_model-00003-of-00003.safetensors", desc: "DiT 3/3", exists: false, size_gb: 0),
            ModelFileItem(name: "text_encoder/model-00001-of-00003.safetensors", desc: "编码器 1/3", exists: false, size_gb: 0),
            ModelFileItem(name: "text_encoder/model-00002-of-00003.safetensors", desc: "编码器 2/3", exists: false, size_gb: 0),
            ModelFileItem(name: "text_encoder/model-00003-of-00003.safetensors", desc: "编码器 3/3", exists: false, size_gb: 0),
            ModelFileItem(name: "vae/diffusion_pytorch_model.safetensors", desc: "图像 VAE", exists: false, size_gb: 0)
        ]
    )
]

struct ResolutionOption: Identifiable, Hashable {
    let id: String
    let labelZh: String
    let labelEn: String
    let width: Int
    let height: Int

    var label: String { L(labelZh, labelEn) }

    static func == (lhs: ResolutionOption, rhs: ResolutionOption) -> Bool {
        lhs.id == rhs.id && lhs.width == rhs.width && lhs.height == rhs.height
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(width)
        hasher.combine(height)
    }
}

let VIDEO_RESOLUTIONS: [ResolutionOption] = [
    ResolutionOption(id: "v_832_480", labelZh: "832 × 480 (16:9 横屏标准 · 推荐)", labelEn: "832 × 480 (16:9 Landscape · Recommended)", width: 832, height: 480),
    ResolutionOption(id: "v_480_832", labelZh: "480 × 832 (9:16 竖屏短视频)", labelEn: "480 × 832 (9:16 Vertical Short)", width: 480, height: 832),
    ResolutionOption(id: "v_1280_720", labelZh: "1280 × 720 (16:9 720P 高清)", labelEn: "1280 × 720 (16:9 720P HD)", width: 1280, height: 720),
    ResolutionOption(id: "v_720_1280", labelZh: "720 × 1280 (9:16 720P 竖屏)", labelEn: "720 × 1280 (9:16 720P Vertical)", width: 720, height: 1280),
    ResolutionOption(id: "v_640_640", labelZh: "640 × 640 (1:1 方形)", labelEn: "640 × 640 (1:1 Square)", width: 640, height: 640)
]

let IMAGE_RESOLUTIONS: [ResolutionOption] = [
    ResolutionOption(id: "i_1024_1024", labelZh: "1024 × 1024 (1:1 超清方图 · 推荐)", labelEn: "1024 × 1024 (1:1 Square HD · Recommended)", width: 1024, height: 1024),
    ResolutionOption(id: "i_1344_768", labelZh: "1344 × 768 (16:9 电影横幅)", labelEn: "1344 × 768 (16:9 Cinematic Widescreen)", width: 1344, height: 768),
    ResolutionOption(id: "i_768_1344", labelZh: "768 × 1344 (9:16 竖版海报)", labelEn: "768 × 1344 (9:16 Vertical Poster)", width: 768, height: 1344),
    ResolutionOption(id: "i_1536_1024", labelZh: "1536 × 1024 (3:2 单反摄影)", labelEn: "1536 × 1024 (3:2 DSLR Photo)", width: 1536, height: 1024)
]

struct PresetTemplate: Identifiable {
    let id: String
    let category: ModelModality
    let nameZh: String
    let nameEn: String
    let visualZh: String
    let visualEn: String
    let soundscape: String
    let music: String

    var name: String { L(nameZh, nameEn) }
    var visual: String { L(visualZh, visualEn) }
}

let PRESET_TEMPLATES: [PresetTemplate] = [
    PresetTemplate(
        id: "tpl_shinkai_train",
        category: .videoAudio,
        nameZh: "[动漫] 新海诚风 · 盛夏樱花铁道口",
        nameEn: "[Anime] Makoto Shinkai · Cherry Blossom Railway",
        visualZh: "Masterpiece Makoto Shinkai anime style, 2D cel-shaded animation. A teenage girl in a Japanese sailor school uniform standing at a sunlit railway crossing in late spring. A green commuter train speeds past in front of her, creating a strong gust of wind that blows her long black hair and a flurry of pink cherry blossom petals across the frame. Dramatic lens flare, glowing cumulous clouds in a deep blue sky, vibrant cinematic lighting, smooth 24fps keyframe animation.",
        visualEn: "Masterpiece Makoto Shinkai anime style, 2D cel-shaded animation. A teenage girl in a Japanese sailor school uniform standing at a sunlit railway crossing in late spring. A green commuter train speeds past in front of her, creating a strong gust of wind that blows her long black hair and a flurry of pink cherry blossom petals across the frame. Dramatic lens flare, glowing cumulous clouds in a deep blue sky, vibrant cinematic lighting, smooth 24fps keyframe animation.",
        soundscape: "Metallic clacking of train wheels on railway tracks, rhythmic dinging of the railroad crossing warning bell, warm spring wind rustling through leaves, a soft gasp from the girl.",
        music: "Emotional and nostalgic solo piano melody joined by warm acoustic guitar and soaring cinematic strings."
    ),
    PresetTemplate(
        id: "tpl_ufotable_duel",
        category: .videoAudio,
        nameZh: "[动漫] 飞碟社风 · 苍蓝雷光剑术对决",
        nameEn: "[Anime] Ufotable Sakuga · Azure Lightning Sword Duel",
        visualZh: "High-budget ufotable anime action sakuga, dynamic fast-paced camera tracking. A silver-haired anime swordsman in a dark haori coat dashes across a shattered stone temple under a blood-red full moon, swinging a katana wreathed in crackling blue lightning and swirling water dragon effects. Sparks and glowing embers fly toward the camera in slow-motion impact frames, intense anime shading, dramatic motion blur.",
        visualEn: "High-budget ufotable anime action sakuga, dynamic fast-paced camera tracking. A silver-haired anime swordsman in a dark haori coat dashes across a shattered stone temple under a blood-red full moon, swinging a katana wreathed in crackling blue lightning and swirling water dragon effects. Sparks and glowing embers fly toward the camera in slow-motion impact frames, intense anime shading, dramatic motion blur.",
        soundscape: "Sharp metallic sword unsheathing and clashing clang, roaring thunder and crackling electric arcs, heavy stone debris crumbling, fierce battle cry.",
        music: "Epic dark orchestral battle music with fast taiko drums, intense choir, and distorted electric guitar riffs."
    ),
    PresetTemplate(
        id: "tpl_iceland_fpv",
        category: .videoAudio,
        nameZh: "[写实] 冰岛巨型瀑布 FPV 穿越机航拍",
        nameEn: "[Realism] Iceland Waterfall FPV Drone Dive",
        visualZh: "FPV drone shot diving down a majestic Icelandic waterfall surrounded by lush green moss and basalt columns under golden hour sunlight, mist rising into a rainbow.",
        visualEn: "FPV drone shot diving down a majestic Icelandic waterfall surrounded by lush green moss and basalt columns under golden hour sunlight, mist rising into a rainbow.",
        soundscape: "Roaring waterfall rushing water, wind whooshing past the camera, distant seabirds calling.",
        music: "Epic cinematic acoustic guitar and soaring cello."
    ),
    PresetTemplate(
        id: "tpl_cyber_poster",
        category: .image,
        nameZh: "[生图] 东方赛博霓虹商业海报（含中文排版）",
        nameEn: "[Image] Cyberpunk Neon Bund Poster (Chinese Title)",
        visualZh: "超清商业电影海报摄影，雨夜霓虹闪烁的未来上海外滩街道，一位身着机能风银色夹克的少女回眸凝视镜头，景深虚化光斑，顶部醒目发光现代中文字体排版写着“未来纪元 2026”，极致光影细节，8K画质。",
        visualEn: "Ultra-HD commercial sci-fi movie poster photography, rain-slicked cyberpunk Shanghai Bund street glowing with neon reflections at night, a young woman in a futuristic silver techwear jacket looking back at the camera, shallow depth of field bokeh flares, bold glowing modern title typography at the top reading \"FUTURE ERA 2026\" (未来纪元 2026), intricate lighting details, 8K.",
        soundscape: "",
        music: ""
    ),
    PresetTemplate(
        id: "tpl_film_cafe",
        category: .image,
        nameZh: "[生图] 胶片质感午后咖啡馆肖像",
        nameEn: "[Image] Hasselblad Film Afternoon Tokyo Cafe",
        visualZh: "Hasselblad medium format film photography, soft golden afternoon sunlight streaming through wooden blinds onto a cozy minimalist Tokyo cafe table, a ceramic pour-over coffee dripper with rising steam beside an open sketchbook, natural film grain, ultra-detailed textures.",
        visualEn: "Hasselblad medium format film photography, soft golden afternoon sunlight streaming through wooden blinds onto a cozy minimalist Tokyo cafe table, a ceramic pour-over coffee dripper with rising steam beside an open sketchbook, natural film grain, ultra-detailed textures.",
        soundscape: "",
        music: ""
    ),
    PresetTemplate(
        id: "tpl_llm_storyboard",
        category: .llmVLM,
        nameZh: "[推理] 为 AI 视频导演生成 3 组新海诚风分镜提示词",
        nameEn: "[Reasoning] Generate 3 Shinkai-Style AI Video Storyboard Prompts",
        visualZh: "请帮我构思 3 组极具画面感的新海诚风格动画短片分镜，每组包含：1) 英文 Visual & Camera 镜头提示词；2) Soundscape 环境音描述；3) Background Music 配乐描述。",
        visualEn: "Please design 3 vivid Makoto Shinkai-style anime short film storyboard shots. For each shot, provide: 1) Visual & Camera prompt; 2) Soundscape & SFX prompt; 3) Background Music prompt.",
        soundscape: "",
        music: ""
    ),
    PresetTemplate(
        id: "tpl_vlm_reverse",
        category: .llmVLM,
        nameZh: "[视觉] 深度解析图片构图并反推生图/生视频 Prompt",
        nameEn: "[Vision] Analyze Image Composition & Reverse-Engineer Prompt",
        visualZh: "请仔细观察这张图片的主体、光影色调、镜头景别与艺术风格，先做简要中文分析，然后反推出一段高质量的英文生图/生视频 Prompt。",
        visualEn: "Carefully analyze the subject, lighting, color palette, camera framing, and artistic style of this image. First give a concise visual breakdown, then write a high-quality English image/video generation prompt.",
        soundscape: "",
        music: ""
    )
]

// MARK: - 网络协议结构

struct LoadedModelSummary: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var mode: String?
    var vram_gb: Double?
    var context_length: Int?

    var localizedName: String {
        if let spec = OPEN_MODEL_CATALOG.first(where: { $0.id == id }) {
            return spec.name
        }
        return localizeServerText(name)
    }
}

struct ColabStatusResponse: Codable {
    var ok: Bool?
    var cuda_available: Bool?
    var gpu_name: String?
    var cpu_utilization_pct: Double?
    var gpu_utilization_pct: Double?
    var vram_free_gb: Double?
    var vram_total_gb: Double?
    var vram_used_gb: Double?
    var model_loaded: Bool?
    var any_model_loaded: Bool?
    var selected_model_id: String?
    var loaded_model_id: String?
    var loaded_model_ids: [String]?
    var loaded_models_detail: [LoadedModelSummary]?
    var current_model: String?
    var message: String?
    var context_length: Int?
    var loaded_context_length: Int?

    var files: [ModelFileItem]?
    var downloaded_count: Int?
    var total_count: Int?
    var all_downloaded: Bool?
    var total_size_gb: Double?
    var drive_persisted: Bool?
    var bf16_shards_count: Int?
    var is_downloading: Bool?
    var is_loading_vram: Bool?
    var task_progress: Double?
    var task_message: String?
    var download_completed_bytes: Double?
    var download_total_bytes: Double?
    var upload_completed_bytes: Double?
    var upload_confirmed_bytes: Double?
    var upload_total_bytes: Double?
    var upload_state: String?
    var upload_live: Bool?
    var transfer_message: String?

    var uptime_seconds: Int?
    var cu_burn_rate_per_hour: Double?
    var session_cu_used: Double?
    var idle_timeout_minutes: Int?
    var idle_remaining_seconds: Int?
    var api_key_enabled: Bool?
    var api_request_count: Int?
    var console_lines: [String]?

    var ram_total_gb: Double?
    var ram_used_gb: Double?
    var ram_free_gb: Double?
    var disk_total_gb: Double?
    var disk_used_gb: Double?
    var disk_free_gb: Double?
    var shm_total_gb: Double?
    var shm_used_gb: Double?
    var shm_free_gb: Double?
    var drive_total_gb: Double?
    var drive_used_gb: Double?
    var drive_free_gb: Double?
    var comfyui: ComfyRemoteStatus?
    var action_ok: Bool?
    var action_message: String?
}

struct ComfyOutputMediaItem: Codable, Identifiable, Hashable {
    var id: String { rel_path }
    var rel_path: String
    var filename: String
    var media_type: String?
    var size_mb: Double?
    var mtime: Int?
}

struct ComfyPresetPackItem: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var badge: String
    var scenario: String
    var approx_size_gb: Double
    var workflows: [String]
    var installed_models: Int
    var total_models: Int
    var workflows_installed: Bool
    var ready: Bool

    var localizedTitle: String {
        guard LanguageManager.shared.isEN else { return title }
        switch id {
        case "wan22_i2v_flf2v":
            return "Wan2.2 14B · Image-to-Video + First/Last Frame Dual Workflows"
        case "minimax_h3_i2v_flf2v":
            return "MiniMax-H3 Turbo · Image-to-Video+Audio + First/Last Frame"
        case "ltx23_flf2v":
            return "LTX-2.3 (22B) · Cinematic Camera Motion First/Last Frame + Audio"
        case "hunyuan15_i2v_1080p":
            return "HunyuanVideo 1.5 · Single-Image Direct 1080P Super-Res Workflow"
        default:
            return localizeServerText(title)
        }
    }

    var localizedBadge: String {
        guard LanguageManager.shared.isEN else { return badge }
        switch id {
        case "wan22_i2v_flf2v":
            return "Beginner Pick · 4-Step Fast"
        case "minimax_h3_i2v_flf2v":
            return "Stereo Audio · 8-Step Turbo"
        case "ltx23_flf2v":
            return "Cinematic Camera · Only 2 Weights"
        case "hunyuan15_i2v_1080p":
            return "720P + 1080P Dual Output"
        default:
            return localizeServerText(badge)
        }
    }

    var localizedScenario: String {
        guard LanguageManager.shared.isEN else { return scenario }
        switch id {
        case "wan22_i2v_flf2v":
            return "Includes 'Single Image to Video' & 'First/Last Frame Smooth Transition' templates (~25s on G4, 100% built-in nodes, zero missing-node errors)"
        case "minimax_h3_i2v_flf2v":
            return "Includes single-image and first/last-frame templates generating HD video with synchronized stereo SFX, dialogue & music in one pass"
        case "ltx23_flf2v":
            return "Optimized for dramatic camera moves between start & end keyframes (e.g. aerial crane dive to low-angle close-up + synthesized soundtrack)"
        case "hunyuan15_i2v_1080p":
            return "Latent super-resolution pipeline enabled by default — upload 1 image to render both 720P base video and 1920×1080 Full HD output"
        default:
            return localizeServerText(scenario)
        }
    }

    static func localizedWorkflowLabel(_ rawName: String) -> String {
        let stripped = rawName.replacingOccurrences(of: ".json", with: "")
        guard LanguageManager.shared.isEN else { return stripped }
        let map: [String: String] = [
            "01_Wan2.2_极速单图生视频(4步傻瓜版)": "01_Wan2.2_Fast_Single_I2V_4Step",
            "02_Wan2.2_首尾帧丝滑过渡(双图4步极速)": "02_Wan2.2_FirstLastFrame_4Step",
            "03_MiniMax-H3_极速图生有声视频(单图带立体声)": "03_MiniMax-H3_Fast_I2VA_Stereo",
            "04_MiniMax-H3_首尾帧有声过渡(双图带立体声)": "04_MiniMax-H3_FirstLastFrame_Stereo",
            "05_LTX-2.3_首尾帧电影运镜(双图极速带音效)": "05_LTX-2.3_Cinematic_FLF2V_Audio",
            "06_Hunyuan1.5_单图直出1080P超清视频": "06_Hunyuan1.5_Direct_1080P_I2V"
        ]
        return map[stripped] ?? stripped
    }
}

let DEFAULT_COMFY_PRESET_PACKS: [ComfyPresetPackItem] = [
    ComfyPresetPackItem(
        id: "wan22_i2v_flf2v",
        title: "万相 Wan2.2 14B · 图生视频 + 首尾帧双工作流",
        badge: "新手首选 · 4步极速",
        scenario: "含「单图动起来」与「首尾双图丝滑过渡」2 套中文画布，G4 约 25 秒出片，纯官方内置节点零红框报错",
        approx_size_gb: 35.4,
        workflows: [
            "01_Wan2.2_极速单图生视频(4步傻瓜版).json",
            "02_Wan2.2_首尾帧丝滑过渡(双图4步极速).json"
        ],
        installed_models: 0,
        total_models: 6,
        workflows_installed: false,
        ready: false
    ),
    ComfyPresetPackItem(
        id: "minimax_h3_i2v_flf2v",
        title: "MiniMax-H3 Turbo · 图生有声视频 + 首尾帧双工作流",
        badge: "自带立体声音效 · 8步加速",
        scenario: "含「单图生有声视频」与「首尾双图有声过渡」2 套极简画布，一次生成高清动态画面 + 同步环境音效/配乐/对白",
        approx_size_gb: 39.1,
        workflows: [
            "03_MiniMax-H3_极速图生有声视频(单图带立体声).json",
            "04_MiniMax-H3_首尾帧有声过渡(双图带立体声).json"
        ],
        installed_models: 0,
        total_models: 5,
        workflows_installed: false,
        ready: false
    ),
    ComfyPresetPackItem(
        id: "ltx23_flf2v",
        title: "LTX-2.3 (22B) · 首尾帧电影级运镜有声工作流",
        badge: "电影推拉摇移 · 仅 2 个权重",
        scenario: "专为首尾关键帧大幅度镜头运动优化（如高空俯拍平滑推镜至低角度特写 + 自动合成配乐音轨）",
        approx_size_gb: 36.3,
        workflows: [
            "05_LTX-2.3_首尾帧电影运镜(双图极速带音效).json"
        ],
        installed_models: 0,
        total_models: 2,
        workflows_installed: false,
        ready: false
    ),
    ComfyPresetPackItem(
        id: "hunyuan15_i2v_1080p",
        title: "混元 HunyuanVideo 1.5 · 单图直出 1080P 超分工作流",
        badge: "720P + 1080P 双路超清",
        scenario: "已默认激活潜空间超分管线，传 1 张图一键自动渲染 720P 原片与 1920×1080 超高清成片",
        approx_size_gb: 43.5,
        workflows: [
            "06_Hunyuan1.5_单图直出1080P超清视频.json"
        ],
        installed_models: 0,
        total_models: 7,
        workflows_installed: false,
        ready: false
    )
]

struct ComfyRemoteStatus: Codable {
    var is_running: Bool?
    var is_starting: Bool?
    var is_syncing_drive: Bool?
    var is_downloading_weight: Bool?
    var installing_pack_id: String?
    var progress: Double?
    var status_message: String?
    var public_url: String?
    var local_port: Int?
    var queue_running: Int?
    var queue_pending: Int?
    var persistence_mode: String?
    var persistence_label: String?
    var drive_persisted: Bool?
    var persist_root: String?
    var custom_nodes_count: Int?
    var models_count: Int?
    var workflows_count: Int?
    var last_sync_ts: Int?
    var recent_outputs: [ComfyOutputMediaItem]?
    var preset_packs: [ComfyPresetPackItem]?
}

struct CompletedMediaItem: Codable, Hashable {
    var index: Int?
    var seed: Int?
    var filename: String
    var video_url: String
    var media_type: String?
    var elapsed: Double?
}

struct LiveTelemetrySnapshot: Codable {
    var cpu_utilization_pct: Double?
    var gpu_utilization_pct: Double?
    var cuda_available: Bool?
    var gpu_name: String?
    var vram_free_gb: Double?
    var vram_total_gb: Double?
    var vram_used_gb: Double?
    var cu_burn_rate_per_hour: Double?
    var ram_total_gb: Double?
    var ram_used_gb: Double?
    var ram_free_gb: Double?
    var disk_total_gb: Double?
    var disk_used_gb: Double?
    var disk_free_gb: Double?
    var shm_total_gb: Double?
    var shm_used_gb: Double?
    var shm_free_gb: Double?
    var drive_total_gb: Double?
    var drive_used_gb: Double?
    var drive_free_gb: Double?
}

struct ColabJobResponse: Codable {
    var job_id: String
    var model_id: String?
    var status: String
    var progress: Double
    var message: String
    var seed: Int?
    var elapsed: Double?
    var filename: String?
    var video_url: String?
    var media_type: String?
    var text_output: String?
    var thinking_output: String?
    var batch_count: Int?
    var completed_count: Int?
    var completed_videos: [CompletedMediaItem]?
    var console_lines: [String]?
    var telemetry: LiveTelemetrySnapshot?
}

struct BridgeAuthStatusResponse: Codable {
    var ok: Bool?
    var logged_in: Bool?
    var email: String?
    var paid_balance: Double?
    var burn_rate_hourly: Double?
    var active_assignments: Int?
    var message: String?
    var error: String?
}

struct LocalMediaItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let filename: String
    let isImage: Bool
    let createdAt: Date
    let elapsedSeconds: Double?
}

func formatDuration(_ sec: Double, compact: Bool = false) -> String {
    let s = max(0.0, sec)
    if s < 60.0 {
        if compact { return String(format: "%.1fs", s) }
        return LanguageManager.shared.isEN
            ? String(format: "%.1f s", s)
            : String(format: "%.1f 秒", s)
    }
    let mins = Int(s) / 60
    let rem = s - Double(mins * 60)
    if compact { return String(format: "%dm%.0fs", mins, rem) }
    return LanguageManager.shared.isEN
        ? String(format: "%dm %.1fs", mins, rem)
        : String(format: "%d分%.1f秒", mins, rem)
}

struct ChatTurnItem: Identifiable, Hashable {
    let id = UUID()
    var role: String      // "user" or "assistant"
    var content: String
    var thinking: String = ""
    var hasImage: Bool = false
}

// MARK: - 文本清理：过滤服务端消息中的 emoji

func stripEmoji(_ text: String) -> String {
    var scalars = String.UnicodeScalarView()
    for s in text.unicodeScalars {
        let p = s.properties
        let v = s.value
        let isEmoji = p.isEmojiPresentation
            || (p.isEmoji && v > 0x238C)
            || v == 0xFE0F || v == 0x200D || v == 0x20E3
            || (0x1F1E6...0x1F1FF).contains(v)
        if !isEmoji { scalars.append(s) }
    }
    var result = String(scalars)
    while result.contains("  ") { result = result.replacingOccurrences(of: "  ", with: " ") }
    return result.trimmingCharacters(in: .whitespaces)
}

// MARK: - 界面色彩主题（左中右三栏高辨识度分界）

struct StudioPalette {
    let colorScheme: ColorScheme

    // 左侧控制栏：冷灰蓝底色
    var sidebarBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.110, green: 0.120, blue: 0.145)
            : Color(red: 0.912, green: 0.928, blue: 0.955)
    }

    // 左侧卡片底色
    var sidebarCardFill: Color {
        colorScheme == .dark
            ? Color(red: 0.155, green: 0.168, blue: 0.200)
            : Color(red: 0.985, green: 0.990, blue: 1.000)
    }

    // 中间主工作区画布底色
    var workspaceCanvas: Color {
        colorScheme == .dark
            ? Color(red: 0.072, green: 0.078, blue: 0.094)
            : Color(red: 0.974, green: 0.978, blue: 0.986)
    }

    // 中间工作区卡片底色
    var workspaceCardFill: Color {
        colorScheme == .dark
            ? Color(red: 0.125, green: 0.135, blue: 0.162)
            : Color.white
    }

    // 右侧运行日志面板顶栏底色
    var logHeaderBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.102, green: 0.112, blue: 0.136)
            : Color(red: 0.924, green: 0.934, blue: 0.954)
    }

    // 右侧运行日志面板背景色
    var logPanelBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.088, green: 0.096, blue: 0.118)
            : Color(red: 0.938, green: 0.945, blue: 0.960)
    }

    // 右侧深色终端视口底色
    var logTerminalFill: Color {
        Color(red: 0.072, green: 0.082, blue: 0.104)
    }

    // 左中右面板分界线颜色
    var splitDivider: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.14)
            : Color(red: 0.76, green: 0.80, blue: 0.86)
    }

    // 卡片边框色
    var cardBorder: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.09)
            : Color(red: 0.82, green: 0.85, blue: 0.90)
    }

    // 输入框底色
    var inputFill: Color {
        colorScheme == .dark
            ? Color(red: 0.090, green: 0.098, blue: 0.118)
            : Color(red: 0.985, green: 0.988, blue: 0.994)
    }
}

// MARK: - 跨环境动态路径与自包含运行支撑

enum LocalRuntimePaths {
    /// 若应用位于源码仓库目录 (<repo>/EasyColab.app)，优先读取仓库内文件以便开发热更新；
    /// 若被独立安装至 /Applications，自动回退使用 EasyColab.app/Contents/Resources 内置资源。
    static var repoRootIfPresent: URL? {
        let fm = FileManager.default
        let bundleParent = Bundle.main.bundleURL.deletingLastPathComponent()
        if fm.fileExists(atPath: bundleParent.appendingPathComponent("app.py").path),
           fm.fileExists(atPath: bundleParent.appendingPathComponent("colab_bridge.py").path) {
            return bundleParent
        }
        let cwd = URL(fileURLWithPath: fm.currentDirectoryPath, isDirectory: true)
        if fm.fileExists(atPath: cwd.appendingPathComponent("app.py").path),
           fm.fileExists(atPath: cwd.appendingPathComponent("colab_bridge.py").path) {
            return cwd
        }
        return nil
    }

    static func resolveBundledOrRepoFile(_ filename: String) -> String {
        let fm = FileManager.default
        if let repo = repoRootIfPresent {
            let p = repo.appendingPathComponent(filename).path
            if fm.fileExists(atPath: p) { return p }
        }
        if let res = Bundle.main.resourceURL {
            let p = res.appendingPathComponent(filename).path
            if fm.fileExists(atPath: p) { return p }
        }
        return filename
    }

    static var appSupportDir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("EasyColab", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var managedVenvDir: URL {
        appSupportDir.appendingPathComponent("venv", isDirectory: true)
    }

    static func findReadyBridgePython() -> String? {
        let fm = FileManager.default
        var candidates: [String] = []
        if let repo = repoRootIfPresent {
            candidates.append(repo.appendingPathComponent(".venv/bin/python").path)
            candidates.append(repo.appendingPathComponent("venv/bin/python").path)
        }
        candidates.append(managedVenvDir.appendingPathComponent("bin/python").path)
        for py in candidates where fm.isExecutableFile(atPath: py) {
            let check = Process()
            check.executableURL = URL(fileURLWithPath: py)
            check.arguments = ["-c", "import colab_cli, google.auth, websocket"]
            check.standardOutput = Pipe()
            check.standardError = Pipe()
            if (try? check.run()) != nil {
                check.waitUntilExit()
                if check.terminationStatus == 0 {
                    return py
                }
            }
        }
        return nil
    }

    static func findSystemPython3() -> String? {
        let fm = FileManager.default
        let candidates = [
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/Library/Frameworks/Python.framework/Versions/Current/bin/python3",
            "/usr/bin/python3"
        ]
        return candidates.first { fm.isExecutableFile(atPath: $0) }
    }
}

// MARK: - 核心视图模型 (ViewModel)

@MainActor
class StudioViewModel: ObservableObject {
    private var cachedBridgePythonBin: String? = nil
    private let tunnelCredentialStore = TunnelCredentialStore()
    private let hfCredentialStore = TunnelCredentialStore.huggingFace
    private var statusSuccessVersion: UInt64 = 0
    private var connectionWarning: String?
    @Published var cpuUtilization: Double?
    @Published var gpuUtilization: Double?

    var bridgeScript: String { LocalRuntimePaths.resolveBundledOrRepoFile("colab_bridge.py") }
    var appPyPath: String { LocalRuntimePaths.resolveBundledOrRepoFile("app.py") }

    @Published var maskServerURL: Bool = UserDefaults.standard.bool(forKey: "maskServerURL") {
        didSet { UserDefaults.standard.set(maskServerURL, forKey: "maskServerURL") }
    }

    func maskedURLDisplay(_ rawURL: String) -> String {
        let trimmed = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard maskServerURL, !trimmed.isEmpty else { return trimmed }
        if let url = URL(string: trimmed), let scheme = url.scheme, url.host != nil {
            return "\(scheme)://••••••••••••"
        }
        return "https://••••••••••••"
    }

    func maskedConsoleDisplay(_ text: String) -> String {
        guard maskServerURL else { return text }
        return text.replacingOccurrences(of: #"https?://[^\s/<>\"']+"#, with: "https://••••••••••••", options: .regularExpression)
    }

    @Published var colabServerURL: String = UserDefaults.standard.string(forKey: "colabServerURL") ?? "" {
        didSet { UserDefaults.standard.set(colabServerURL, forKey: "colabServerURL") }
    }
    @Published var hfToken: String = "" {
        didSet { hfCredentialMessage = "" }
    }
    @Published var hfCredentialMessage: String = ""
    @Published var useCustomDomain: Bool = UserDefaults.standard.bool(forKey: "useCustomDomain") {
        didSet { UserDefaults.standard.set(useCustomDomain, forKey: "useCustomDomain") }
    }
    @Published var customDomainURL: String = UserDefaults.standard.string(forKey: "customDomainURL") ?? "" {
        didSet { UserDefaults.standard.set(customDomainURL, forKey: "customDomainURL") }
    }
    @Published var cloudflareTunnelToken: String = "" {
        didSet { tunnelCredentialMessage = "" }
    }
    @Published var tunnelCredentialMessage: String = ""

    // 默认初始文案（支持中英文双向无损切换）
    static let defaultGpuNameZh = "未连接 Colab 服务端"
    static let defaultGpuNameEn = "Colab Server Disconnected"
    static let defaultModelNameZh = "未加载"
    static let defaultModelNameEn = "Not Loaded"
    static let defaultComfyStatusZh = "尚未启动云端 ComfyUI 工作台"
    static let defaultComfyStatusEn = "Cloud ComfyUI Studio Not Started"
    static let defaultComfyPersistZh = "Google Drive 自动软链持久化"
    static let defaultComfyPersistEn = "Google Drive Auto-Symlink Persistence"
    static let defaultReadyStatusZh = "就绪：默认已选 G4 (RTX PRO 6000 · 96GB)，可在左侧一键唤醒实例并部署模型。"
    static let defaultReadyStatusEn = "Ready: G4 (RTX PRO 6000 · 96GB) selected by default. Wake & deploy from the left sidebar."
    static let defaultWelcomeLinesZh: [String] = [
        "欢迎使用 EasyColab 多模态云端算力工作台",
        "默认搭载 G4 (RTX PRO 6000 · 96GB)，支持一键部署 ComfyUI 节点工作台 (云盘软链持久化)、MiniMax-H3、Qwen3.8-27B (UD-Q4_K_M GGUF 100 tok/s / BF16)、Qwen-Image-2.1 与 Z-Image-Turbo。"
    ]
    static let defaultWelcomeLinesEn: [String] = [
        "Welcome to EasyColab Multimodal Cloud GPU Studio",
        "Powered by G4 (RTX PRO 6000 · 96GB) by default — 1-click deploy ComfyUI Node Studio (Drive symlink persistence), MiniMax-H3, Qwen3.8-27B (UD-Q4_K_M GGUF 100 tok/s / BF16), Qwen-Image-2.1 & Z-Image-Turbo."
    ]
    static let clearedConsoleLineZh = "已清空历史输出，正在监听云端实时日志..."
    static let clearedConsoleLineEn = "Cleared log history. Listening for live cloud logs..."

    // Colab CLI 唤醒与真实账本状态
    @Published var cliLoggedIn: Bool = false
    @Published var accountEmail: String = ""
    @Published var showOAuthCodeInput: Bool = false
    @Published var oauthCodeText: String = ""
    @Published var officialCUBalance: Double? = nil

    var displayAccountLabel: String {
        guard cliLoggedIn else { return L("未绑定", "Unbound") }
        let raw = accountEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return L("已连接", "Connected") }
        if maskServerURL, let atIdx = raw.firstIndex(of: "@") {
            let prefix = String(raw[..<atIdx].prefix(2))
            let domain = String(raw[atIdx...])
            return "\(prefix)•••\(domain)"
        }
        return raw
    }
    @Published var officialBurnRate: Double? = nil
    @Published var activeVMCount: Int = 0
    @Published var wakeGPUChoice: String = {
        let saved = UserDefaults.standard.string(forKey: "wakeGPUChoiceV2") ?? "G4"
        return ["G4", "H100", "A100", "L4", "T4"].contains(saved) ? saved : "G4"
    }() {
        didSet { UserDefaults.standard.set(wakeGPUChoice, forKey: "wakeGPUChoiceV2") }
    }
    @Published var isWakingColab: Bool = false

    // 远端 GPU 与多模型驻留状态
    @Published var isConnected: Bool = false
    @Published var gpuName: String = L(StudioViewModel.defaultGpuNameZh, StudioViewModel.defaultGpuNameEn) {
        didSet { let c = stripEmoji(gpuName); if c != gpuName { gpuName = c } }
    }
    @Published var vramFreeGB: Double = 0.0
    @Published var vramTotalGB: Double = 0.0
    @Published var vramUsedGB: Double = 0.0
    @Published var ramTotalGB: Double = 0.0
    @Published var ramUsedGB: Double = 0.0
    @Published var ramFreeGB: Double = 0.0
    @Published var diskTotalGB: Double = 0.0
    @Published var diskUsedGB: Double = 0.0
    @Published var diskFreeGB: Double = 0.0
    @Published var shmTotalGB: Double = 0.0
    @Published var shmUsedGB: Double = 0.0
    @Published var shmFreeGB: Double = 0.0
    @Published var driveTotalGB: Double = 0.0
    @Published var driveUsedGB: Double = 0.0
    @Published var driveFreeGB: Double = 0.0
    @Published var vramHistoryPct: [Double] = []
    @Published var ramHistoryPct: [Double] = []
    @Published var diskHistoryPct: [Double] = []
    @Published var combinedTelemetryChartMode: Bool = false
    @Published var selectedModelId: String = "minimax_h3"
    @Published var loadedModelId: String? = nil
    @Published var loadedModelIds: [String] = []
    @Published var loadedModelsDetail: [LoadedModelSummary] = []
    @Published var modelLoaded: Bool = false
    @Published var isUnloadingModel: Bool = false
    @Published var currentModelName: String = L(StudioViewModel.defaultModelNameZh, StudioViewModel.defaultModelNameEn) {
        didSet { let c = stripEmoji(currentModelName); if c != currentModelName { currentModelName = c } }
    }

    // 算力额度账本
    @Published var totalBudgetCU: Double = {
        let saved = UserDefaults.standard.double(forKey: "totalBudgetCU")
        return saved > 0 ? saved : 2000.0
    }() {
        didSet { UserDefaults.standard.set(totalBudgetCU, forKey: "totalBudgetCU") }
    }
    @Published var uptimeSeconds: Int = 0
    @Published var cuBurnRatePerHour: Double = 0.0
    @Published var sessionCUUsed: Double = 0.0
    @Published var idleTimeoutMinutes: Int = {
        if UserDefaults.standard.object(forKey: "idleTimeoutMinutes") == nil { return 30 }
        let saved = UserDefaults.standard.integer(forKey: "idleTimeoutMinutes")
        return [0, 15, 30, 60].contains(saved) ? saved : 30
    }() {
        didSet {
            UserDefaults.standard.set(idleTimeoutMinutes, forKey: "idleTimeoutMinutes")
        }
    }
    @Published var idleRemainingSeconds: Int = 1800
    private var remoteIdleSynced: Bool = false
    @Published var drivePersisted: Bool = false
    @Published var bf16ShardsCount: Int = 0
    @Published var liveConsoleLines: [String] = (
        LanguageManager.shared.isEN ? StudioViewModel.defaultWelcomeLinesEn : StudioViewModel.defaultWelcomeLinesZh
    ) {
        didSet { let c = liveConsoleLines.map(stripEmoji); if c != liveConsoleLines { liveConsoleLines = c } }
    }

    // 当前选中模型的权重明细
    @Published var modelFiles: [ModelFileItem] = OPEN_MODEL_CATALOG[0].defaultFiles
    @Published var downloadedCount: Int = 0
    @Published var totalFileCount: Int = OPEN_MODEL_CATALOG[0].defaultFiles.count
    @Published var allDownloaded: Bool = false
    @Published var totalDiskSizeGB: Double = 0.0
    @Published var isDownloadingWeights: Bool = false
    @Published var isLoadingModel: Bool = false

    // ComfyUI 云端工作台与 Google Drive 软链持久化状态
    @Published var comfyRunning: Bool = false
    @Published var comfyStarting: Bool = false
    @Published var comfySyncingDrive: Bool = false
    @Published var comfyDownloadingWeight: Bool = false
    @Published var comfyInstallingPackId: String = ""
    @Published var comfyPresetPacks: [ComfyPresetPackItem] = DEFAULT_COMFY_PRESET_PACKS
    @Published var comfyProgress: Double = 0.0
    @Published var comfyStatusMessage: String = L(StudioViewModel.defaultComfyStatusZh, StudioViewModel.defaultComfyStatusEn) {
        didSet { let c = stripEmoji(comfyStatusMessage); if c != comfyStatusMessage { comfyStatusMessage = c } }
    }
    @Published var comfyPublicURL: String = ""
    @Published var comfyQueueRunning: Int = 0
    @Published var comfyQueuePending: Int = 0
    @Published var comfyPersistenceLabel: String = L(StudioViewModel.defaultComfyPersistZh, StudioViewModel.defaultComfyPersistEn)
    @Published var comfyDrivePersisted: Bool = false
    @Published var comfyPersistRoot: String = "/content/drive/MyDrive/EasyColab_ComfyUI"
    @Published var comfyCustomNodesCount: Int = 0
    @Published var comfyModelsCount: Int = 0
    @Published var comfyWorkflowsCount: Int = 0
    @Published var comfyRecentOutputs: [ComfyOutputMediaItem] = []
    @Published var comfyUnloadOthersOnStart: Bool = false
    @Published var comfyWeightSourceInput: String = ""
    @Published var comfyWeightFilenameInput: String = ""
    @Published var comfyWeightSubfolder: String = "diffusion_models"
    @Published var comfyPullingOutputRelPath: String? = nil
    @Published var modelTaskProgress: Double = 0.0
    @Published var downloadCompletedBytes: Double = 0
    @Published var downloadTotalBytes: Double = 0
    @Published var uploadCompletedBytes: Double = 0
    @Published var uploadConfirmedBytes: Double = 0
    @Published var uploadTotalBytes: Double = 0
    @Published var uploadState: String = ""
    @Published var uploadLive: Bool = false
    @Published var transferMessage: String = ""

    @Published var selectedPrecision: String = "bf16"
    @Published var selectedOffload: String = "disk"

    // 任务模式与生成参数
    @Published var taskModeId: String = "t2va"
    @Published var visualPrompt: String = PRESET_TEMPLATES[0].visual
    @Published var negativePrompt: String = ""
    @Published var soundscapePrompt: String = PRESET_TEMPLATES[0].soundscape
    @Published var musicPrompt: String = PRESET_TEMPLATES[0].music
    @Published var firstFrameImage: NSImage? = nil
    @Published var lastFrameImage: NSImage? = nil
    @Published var selectedVideoResolution: ResolutionOption = VIDEO_RESOLUTIONS[0]
    @Published var selectedImageResolution: ResolutionOption = IMAGE_RESOLUTIONS[0]
    @Published var numFrames: Double = 124
    @Published var inferenceSteps: Double = 35
    @Published var fps: Double = 24
    @Published var seed: Int = 42
    @Published var randomizeSeed: Bool = true
    @Published var batchCount: Int = 1
    @Published var denoisingStrength: Double = 0.70

    // Qwen3.8-27B / GGUF 对话与双协议 API 网关专属参数（支持最高 256K 上下文）
    @Published var contextLengthK: Int = {
        let saved = UserDefaults.standard.integer(forKey: "qwenContextLengthK")
        if saved >= 4 && saved <= 256 { return saved }
        return 32
    }() {
        didSet {
            let clamped = contextLengthK.clamped(to: 4...256)
            if contextLengthK != clamped {
                contextLengthK = clamped
                return
            }
            UserDefaults.standard.set(clamped, forKey: "qwenContextLengthK")
        }
    }
    @Published var loadedContextLengthTokens: Int = 0
    private var remoteContextSynced: Bool = false

    var contextLengthTokens: Int {
        contextLengthK.clamped(to: 4...256) * 1024
    }

    @Published var enableThinking: Bool = true {
        didSet {
            // 自动对齐 Unsloth Qwen3.8 官方推荐混合思考采样表
            if enableThinking {
                temperature = 1.0
                topP = 0.95
                presencePenalty = 0.0
            } else {
                temperature = 0.7
                topP = 0.80
                presencePenalty = 1.5
            }
        }
    }
    @Published var reasoningEffort: String = {
        let saved = UserDefaults.standard.string(forKey: "reasoningEffort") ?? "medium"
        return ["low", "medium", "high", "xhigh"].contains(saved) ? saved : "medium"
    }() {
        didSet {
            UserDefaults.standard.set(reasoningEffort, forKey: "reasoningEffort")
        }
    }
    @Published var maxNewTokens: Double = 16384
    @Published var temperature: Double = 1.0
    @Published var topP: Double = 0.95
    @Published var presencePenalty: Double = 0.0
    @Published var chatHistory: [ChatTurnItem] = []

    @Published var apiKeyEnabled: Bool = {
        if UserDefaults.standard.object(forKey: "apiKeyEnabled") == nil { return true }
        return UserDefaults.standard.bool(forKey: "apiKeyEnabled")
    }() {
        didSet {
            UserDefaults.standard.set(apiKeyEnabled, forKey: "apiKeyEnabled")
            Task { await syncApiKeyToColab() }
        }
    }
    @Published var apiAccessKey: String = {
        if let saved = UserDefaults.standard.string(forKey: "apiAccessKey"), !saved.isEmpty {
            return saved
        }
        let generated = "sk-colab-" + UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(20).lowercased()
        UserDefaults.standard.set(generated, forKey: "apiAccessKey")
        return generated
    }() {
        didSet {
            UserDefaults.standard.set(apiAccessKey, forKey: "apiAccessKey")
        }
    }
    @Published var apiRequestCount: Int = 0
    @Published var remoteApiKeySynced: Bool = false

    // 任务进度与生成耗时状态
    @Published var isGenerating: Bool = false
    @Published var progressValue: Double = 0.0
    @Published var currentJobElapsed: Double = 0.0
    @Published var lastCompletedElapsed: Double? = nil
    @Published var mediaElapsedMap: [String: Double] = (
        UserDefaults.standard.dictionary(forKey: "mediaElapsedSecondsMap") as? [String: Double]
    ) ?? [:] {
        didSet {
            UserDefaults.standard.set(mediaElapsedMap, forKey: "mediaElapsedSecondsMap")
        }
    }
    @Published var statusMessage: String = L(StudioViewModel.defaultReadyStatusZh, StudioViewModel.defaultReadyStatusEn) {
        didSet { let c = stripEmoji(statusMessage); if c != statusMessage { statusMessage = c } }
    }

    var displayGpuName: String { localizeServerText(gpuName) }
    var displayCurrentModelName: String { localizeServerText(currentModelName) }
    var displayComfyStatusMessage: String { localizeServerText(comfyStatusMessage) }
    var displayComfyPersistenceLabel: String { localizeServerText(comfyPersistenceLabel) }
    var displayStatusMessage: String { localizeServerText(statusMessage) }

    // 多媒体预览与本地历史记录
    @Published var currentMediaURL: URL? = nil
    @Published var currentPreviewImage: NSImage? = nil
    @Published var player: AVPlayer? = nil
    @Published var localMediaItems: [LocalMediaItem] = []
    @Published var showColabGuideSheet: Bool = false
    @Published var guideInitialStep: Int = 0
    @Published var showDisconnectConfirm: Bool = false

    private var languageObserver: NSObjectProtocol? = nil

    func toggleLanguage() {
        LanguageManager.shared.toggle()
    }

    private func syncLocalizedDynamicTexts() {
        let isEN = LanguageManager.shared.isEN
        if gpuName == Self.defaultGpuNameZh || gpuName == Self.defaultGpuNameEn {
            gpuName = isEN ? Self.defaultGpuNameEn : Self.defaultGpuNameZh
        }
        if currentModelName == Self.defaultModelNameZh || currentModelName == Self.defaultModelNameEn {
            currentModelName = isEN ? Self.defaultModelNameEn : Self.defaultModelNameZh
        }
        if comfyStatusMessage == Self.defaultComfyStatusZh || comfyStatusMessage == Self.defaultComfyStatusEn {
            comfyStatusMessage = isEN ? Self.defaultComfyStatusEn : Self.defaultComfyStatusZh
        }
        if comfyPersistenceLabel == Self.defaultComfyPersistZh || comfyPersistenceLabel == Self.defaultComfyPersistEn {
            comfyPersistenceLabel = isEN ? Self.defaultComfyPersistEn : Self.defaultComfyPersistZh
        }
        if statusMessage == Self.defaultReadyStatusZh || statusMessage == Self.defaultReadyStatusEn {
            statusMessage = isEN ? Self.defaultReadyStatusEn : Self.defaultReadyStatusZh
        }
        if liveConsoleLines == Self.defaultWelcomeLinesZh || liveConsoleLines == Self.defaultWelcomeLinesEn {
            liveConsoleLines = isEN ? Self.defaultWelcomeLinesEn : Self.defaultWelcomeLinesZh
        } else if liveConsoleLines == [Self.clearedConsoleLineZh] || liveConsoleLines == [Self.clearedConsoleLineEn] {
            liveConsoleLines = [isEN ? Self.clearedConsoleLineEn : Self.clearedConsoleLineZh]
        }
        for tpl in PRESET_TEMPLATES where tpl.visualZh != tpl.visualEn {
            if visualPrompt == tpl.visualZh || visualPrompt == tpl.visualEn {
                visualPrompt = tpl.visual
                break
            }
        }
    }

    func openOnboardingGuide(step: Int = 0) {
        guideInitialStep = max(0, min(3, step))
        showColabGuideSheet = true
    }

    private var heartbeatTask: Task<Void, Never>? = nil
    private var generationTimerTask: Task<Void, Never>? = nil
    private var generationStartedAt: Date? = nil
    private var consecutiveStatusFailures: Int = 0
    private var lastTelemetrySampleDate: Date = .distantPast
    private let maxTelemetrySamples: Int = 48

    private func recordTelemetrySample(force: Bool = false) {
        let now = Date()
        if !force && now.timeIntervalSince(lastTelemetrySampleDate) < 0.85 {
            return
        }
        lastTelemetrySampleDate = now

        if vramTotalGB > 0 {
            let pct = min(1.0, max(0.0, vramUsedGB / vramTotalGB))
            if vramHistoryPct.isEmpty {
                vramHistoryPct = Array(repeating: pct, count: 14)
            } else {
                vramHistoryPct.append(pct)
                if vramHistoryPct.count > maxTelemetrySamples {
                    vramHistoryPct.removeFirst(vramHistoryPct.count - maxTelemetrySamples)
                }
            }
        }

        if ramTotalGB > 0 {
            let pct = min(1.0, max(0.0, ramUsedGB / ramTotalGB))
            if ramHistoryPct.isEmpty {
                ramHistoryPct = Array(repeating: pct, count: 14)
            } else {
                ramHistoryPct.append(pct)
                if ramHistoryPct.count > maxTelemetrySamples {
                    ramHistoryPct.removeFirst(ramHistoryPct.count - maxTelemetrySamples)
                }
            }
        }

        if diskTotalGB > 0 {
            let pct = min(1.0, max(0.0, diskUsedGB / diskTotalGB))
            if diskHistoryPct.isEmpty {
                diskHistoryPct = Array(repeating: pct, count: 14)
            } else {
                diskHistoryPct.append(pct)
                if diskHistoryPct.count > maxTelemetrySamples {
                    diskHistoryPct.removeFirst(diskHistoryPct.count - maxTelemetrySamples)
                }
            }
        }
    }

    private func applyLiveTelemetrySnapshot(_ snap: LiveTelemetrySnapshot) {
        cpuUtilization = snap.cpu_utilization_pct
        gpuUtilization = snap.gpu_utilization_pct
        if let g = snap.gpu_name, !g.isEmpty { gpuName = g }
        if let vf = snap.vram_free_gb { vramFreeGB = vf }
        if let vt = snap.vram_total_gb { vramTotalGB = vt }
        if let vu = snap.vram_used_gb { vramUsedGB = vu }
        if let cr = snap.cu_burn_rate_per_hour { cuBurnRatePerHour = cr }
        if let rt = snap.ram_total_gb, rt > 0 { ramTotalGB = rt }
        if let ru = snap.ram_used_gb { ramUsedGB = ru }
        if let rf = snap.ram_free_gb { ramFreeGB = rf }
        if let dt = snap.disk_total_gb, dt > 0 { diskTotalGB = dt }
        if let du = snap.disk_used_gb { diskUsedGB = du }
        if let df = snap.disk_free_gb { diskFreeGB = df }
        if let st = snap.shm_total_gb { shmTotalGB = st }
        if let su = snap.shm_used_gb { shmUsedGB = su }
        if let sf = snap.shm_free_gb { shmFreeGB = sf }
        if let gt = snap.drive_total_gb, gt > 0 { driveTotalGB = gt }
        if let gu = snap.drive_used_gb { driveUsedGB = gu }
        if let gf = snap.drive_free_gb { driveFreeGB = gf }
        recordTelemetrySample()
    }

    func elapsedForMedia(_ url: URL?) -> Double? {
        guard let url else { return nil }
        return mediaElapsedMap[url.lastPathComponent]
    }

    private var activeGenerationToken = UUID()

    private func stripConsoleProgressBars() {
        if let sepIdx = liveConsoleLines.firstIndex(where: { $0.contains("实时下载/采样进度流") }) {
            liveConsoleLines = Array(liveConsoleLines.prefix(sepIdx))
        }
    }

    private func startLiveGenerationTimer() {
        generationTimerTask?.cancel()
        generationStartedAt = Date()
        currentJobElapsed = 0.0
        generationTimerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard let self, self.isGenerating, let started = self.generationStartedAt else { break }
                let localElapsed = Date().timeIntervalSince(started)
                if localElapsed > self.currentJobElapsed {
                    self.currentJobElapsed = localElapsed
                }
            }
        }
    }

    private func stopLiveGenerationTimer() {
        generationTimerTask?.cancel()
        generationTimerTask = nil
        generationStartedAt = nil
    }

    private func resetStaleRemoteRuntimeState(reason: String) {
        connectionWarning = reason
        cpuUtilization = nil
        gpuUtilization = nil
        let hadActiveState = isConnected
            || !loadedModelsDetail.isEmpty
            || !loadedModelIds.isEmpty
            || modelLoaded
            || isGenerating
            || isLoadingModel
            || isDownloadingWeights
            || vramTotalGB > 0

        stopLiveGenerationTimer()
        isConnected = false
        modelLoaded = false
        loadedModelId = nil
        loadedModelIds = []
        loadedModelsDetail = []
        isGenerating = false
        isLoadingModel = false
        isDownloadingWeights = false
        isUnloadingModel = false
        comfyRunning = false
        comfyStarting = false
        comfySyncingDrive = false
        comfyDownloadingWeight = false
        comfyInstallingPackId = ""
        comfyPublicURL = ""
        comfyQueueRunning = 0
        comfyQueuePending = 0
        progressValue = 0.0
        modelTaskProgress = 0.0
        downloadCompletedBytes = 0
        downloadTotalBytes = 0
        uploadCompletedBytes = 0
        uploadConfirmedBytes = 0
        uploadTotalBytes = 0
        uploadState = ""
        uploadLive = false
        transferMessage = ""
        vramUsedGB = 0.0
        vramFreeGB = 0.0
        vramTotalGB = 0.0
        ramTotalGB = 0.0
        ramUsedGB = 0.0
        ramFreeGB = 0.0
        diskTotalGB = 0.0
        diskUsedGB = 0.0
        diskFreeGB = 0.0
        shmTotalGB = 0.0
        shmUsedGB = 0.0
        shmFreeGB = 0.0
        driveTotalGB = 0.0
        driveUsedGB = 0.0
        driveFreeGB = 0.0
        vramHistoryPct = []
        ramHistoryPct = []
        diskHistoryPct = []
        lastTelemetrySampleDate = .distantPast
        cuBurnRatePerHour = 0.0
        loadedContextLengthTokens = 0
        remoteContextSynced = false
        remoteIdleSynced = false
        remoteApiKeySynced = false
        gpuName = L(Self.defaultGpuNameZh, Self.defaultGpuNameEn)

        if hadActiveState && !reason.isEmpty {
            statusMessage = reason
        }
    }

    private func clearLocalLoadedModelRecord(_ modelId: String) {
        if modelId == "all" {
            loadedModelIds = []
            loadedModelsDetail = []
            loadedModelId = nil
            modelLoaded = false
            loadedContextLengthTokens = 0
        } else {
            loadedModelIds.removeAll { $0 == modelId }
            loadedModelsDetail.removeAll { $0.id == modelId }
            if loadedModelId == modelId {
                loadedModelId = loadedModelIds.first
            }
            modelLoaded = loadedModelIds.contains(selectedModelId)
            if !isQwenLoadedInVRAM {
                loadedContextLengthTokens = 0
            }
        }
    }

    let localSaveDir: URL = {
        let moviesDir = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first!
        let dir = moviesDir.appendingPathComponent("EasyColab", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    let legacySaveDirs: [URL] = {
        let moviesDir = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first!
        return [
            moviesDir.appendingPathComponent("Aevix", isDirectory: true),
            moviesDir.appendingPathComponent("Colab_AI_Studio", isDirectory: true),
            moviesDir.appendingPathComponent("MiniMax_H3_Videos", isDirectory: true)
        ]
    }()

    var activeModelSpec: OpenModelSpec {
        OPEN_MODEL_CATALOG.first(where: { $0.id == selectedModelId }) ?? OPEN_MODEL_CATALOG[0]
    }

    var activeModeItem: TaskModeItem {
        activeModelSpec.modes.first(where: { $0.id == taskModeId }) ?? activeModelSpec.modes[0]
    }

    var isSelectedModelLoadedInVRAM: Bool {
        loadedModelIds.contains(selectedModelId) || (modelLoaded && loadedModelId == selectedModelId)
    }

    var isQwenLoadedInVRAM: Bool {
        OPEN_MODEL_CATALOG.contains { spec in
            spec.modality == .llmVLM
                && (loadedModelIds.contains(spec.id) || (modelLoaded && loadedModelId == spec.id))
        }
    }

    init() {
        do {
            hfToken = try hfCredentialStore.load()
            if !hfToken.isEmpty {
                hfCredentialMessage = L("HF Token 已从钥匙串恢复。", "HF Token restored from Keychain.")
            }
        } catch {
            hfCredentialMessage = L("无法读取 HF Token，请解锁钥匙串或重新填写。", "Cannot read HF Token. Unlock Keychain or re-enter it.")
        }
        do {
            cloudflareTunnelToken = try tunnelCredentialStore.load()
            if !cloudflareTunnelToken.isEmpty {
                tunnelCredentialMessage = L("已从钥匙串读取 Token", "Token restored from Keychain")
            }
        } catch {
            tunnelCredentialMessage = L("无法读取钥匙串，请解锁或重新填写 Token。", "Cannot read Keychain. Unlock it or re-enter the token.")
        }
        refreshLocalMedia()
        startBackgroundTelemetryLoop()
        languageObserver = NotificationCenter.default.addObserver(
            forName: .easyColabLanguageDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.syncLocalizedDynamicTexts()
                self.objectWillChange.send()
            }
        }
        Task {
            await refreshOfficialColabAccountUsage()
        }
    }

    deinit {
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
        }
    }

    func switchSelectedModel(_ spec: OpenModelSpec) {
        guard selectedModelId != spec.id else { return }
        selectedModelId = spec.id
        taskModeId = spec.modes[0].id
        inferenceSteps = spec.defaultSteps
        selectedPrecision = "bf16"
        modelFiles = spec.defaultFiles
        downloadedCount = 0
        totalFileCount = spec.defaultFiles.count
        allDownloaded = false
        totalDiskSizeGB = 0.0
        modelLoaded = loadedModelIds.contains(spec.id) || (loadedModelId == spec.id)

        // 自动填入匹配该模态的首条示例提示词（若当前框还是另一模态的默认模板）
        if let sample = PRESET_TEMPLATES.first(where: {
            $0.category == spec.modality || (spec.modality == .video && $0.category == .videoAudio)
        }) {
            visualPrompt = sample.visual
            soundscapePrompt = sample.soundscape
            musicPrompt = sample.music
        }

        if spec.modality == .comfyUI {
            if isConnected {
                statusMessage = comfyRunning && !comfyPublicURL.isEmpty
                    ? L("ComfyUI 云端节点工作台正在运行，可一键在浏览器打开全屏画布。", "ComfyUI Cloud Node Studio is running. Open the fullscreen canvas in your browser.")
                    : L("已切换至 ComfyUI 节点工作台，点击「一键拉起云端 ComfyUI」即可挂载 Google Drive 软链并开通画布。", "Switched to ComfyUI Node Studio. Click 'Deploy & Open Cloud ComfyUI' to mount Google Drive symlinks and launch the canvas.")
            } else {
                statusMessage = L("已切换至 ComfyUI 节点工作台，唤醒并连接 G4 实例后即可一键部署并持久化到 Google Drive。", "Switched to ComfyUI Node Studio. Wake & connect a G4 instance to deploy and persist to Google Drive.")
            }
            return
        }

        if isConnected {
            Task {
                await notifyRemoteSelectModel(spec.id)
            }
        } else {
            statusMessage = L(
                "已切换至 \(spec.name) (\(spec.repoId))，连接 Colab 后即可一键下载并加载至显存。",
                "Switched to \(spec.name) (\(spec.repoId)). Connect to Colab to download & load into VRAM."
            )
        }
    }

    private func notifyRemoteSelectModel(_ modelId: String) async {
        let base = normalizedBaseURL
        guard !base.isEmpty, let url = URL(string: "\(base)/minimax_api/select_model") else { return }
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: ["model_id": modelId])
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode(ColabStatusResponse.self, from: data)
            applyStatusResponse(decoded)
            if isSelectedModelLoadedInVRAM {
                statusMessage = L(
                    "\(activeModelSpec.name) 已驻留 GPU 显存，可直接开始推理！",
                    "\(activeModelSpec.name) is resident in GPU VRAM and ready for inference!"
                )
            } else if allDownloaded {
                statusMessage = L(
                    "\(activeModelSpec.name) 权重已在磁盘就绪，请点击左侧「加载到显存」。",
                    "\(activeModelSpec.name) weights are ready on disk. Click 'Load to VRAM' on the left."
                )
            } else {
                statusMessage = L(
                    "已切换至 \(activeModelSpec.name) | 权重进度 \(downloadedCount)/\(totalFileCount)，请先点击「下载权重」。",
                    "Switched to \(activeModelSpec.name) | Weights \(downloadedCount)/\(totalFileCount). Click 'Download Weights' first."
                )
            }
        } catch {}
    }

    var normalizedBaseURL: String {
        var raw = colabServerURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while raw.hasSuffix("/") { raw.removeLast() }
        return raw
    }

    var formattedUptime: String {
        let h = uptimeSeconds / 3600
        let m = (uptimeSeconds % 3600) / 60
        let s = uptimeSeconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    var formattedIdleRemaining: String {
        if idleTimeoutMinutes <= 0 || idleRemainingSeconds < 0 {
            return L("已关闭自动休眠", "Auto-sleep disabled")
        }
        let m = idleRemainingSeconds / 60
        let s = idleRemainingSeconds % 60
        return L(
            "\(m)分\(String(format: "%02d", s))秒后自动释放实例",
            "Auto-release in \(m)m \(String(format: "%02d", s))s"
        )
    }

    var displayRemainingCU: Double {
        if let official = officialCUBalance { return official }
        return max(0.0, totalBudgetCU - sessionCUUsed)
    }

    var displayBurnRate: Double {
        if let rate = officialBurnRate, rate > 0 || !isConnected { return rate }
        return cuBurnRatePerHour
    }

    // MARK: - 本地 colab_bridge.py 交互与零配置环境自举
    private func ensureBridgePythonBin(installIfMissing: Bool) async -> String? {
        if let cached = cachedBridgePythonBin, FileManager.default.isExecutableFile(atPath: cached) {
            return cached
        }
        let existing = await Task.detached(priority: .userInitiated) {
            LocalRuntimePaths.findReadyBridgePython()
        }.value
        if let existing {
            cachedBridgePythonBin = existing
            return existing
        }
        guard installIfMissing else { return nil }

        guard let sysPy = LocalRuntimePaths.findSystemPython3() else {
            statusMessage = L(
                "未检测到 macOS Python 3 环境，请先安装 Xcode Command Line Tools (xcode-select --install)。",
                "macOS Python 3 not found. Please install Xcode Command Line Tools (xcode-select --install)."
            )
            return nil
        }

        let venvDir = LocalRuntimePaths.managedVenvDir
        let venvPy = venvDir.appendingPathComponent("bin/python").path
        let reqFile = LocalRuntimePaths.resolveBundledOrRepoFile("requirements.txt")
        let hasReqFile = FileManager.default.fileExists(atPath: reqFile)

        statusMessage = L(
            "首次使用正在自动初始化本地 Colab 连接依赖环境 (约 15~30 秒)...",
            "Initializing local Colab bridge Python dependencies for first-time setup (~15–30s)..."
        )
        liveConsoleLines.append(L(
            "[本地初始化] 正在于 ~/Library/Application Support/EasyColab/venv 安装 google-colab-cli 依赖...",
            "[Local Init] Installing google-colab-cli dependencies in ~/Library/Application Support/EasyColab/venv..."
        ))

        let ok = await Task.detached(priority: .userInitiated) { () -> Bool in
            let mkProc = Process()
            mkProc.executableURL = URL(fileURLWithPath: sysPy)
            mkProc.arguments = ["-m", "venv", venvDir.path]
            mkProc.standardOutput = Pipe()
            mkProc.standardError = Pipe()
            do {
                try mkProc.run()
                mkProc.waitUntilExit()
                guard mkProc.terminationStatus == 0 else { return false }
            } catch {
                return false
            }

            let pipProc = Process()
            pipProc.executableURL = URL(fileURLWithPath: venvPy)
            if hasReqFile {
                pipProc.arguments = ["-m", "pip", "install", "-q", "--upgrade", "pip", "-r", reqFile]
            } else {
                pipProc.arguments = [
                    "-m", "pip", "install", "-q", "--upgrade", "pip",
                    "google-colab-cli>=0.7.5",
                    "google-auth>=2.28.0",
                    "google-auth-oauthlib>=1.2.0",
                    "requests>=2.31.0",
                    "websocket-client>=1.7.0"
                ]
            }
            pipProc.standardOutput = Pipe()
            pipProc.standardError = Pipe()
            do {
                try pipProc.run()
                pipProc.waitUntilExit()
                return pipProc.terminationStatus == 0
            } catch {
                return false
            }
        }.value

        if ok, FileManager.default.isExecutableFile(atPath: venvPy) {
            cachedBridgePythonBin = venvPy
            liveConsoleLines.append(L(
                "[本地初始化] Colab 本地连接组件已就绪。",
                "[Local Init] Local Colab bridge environment is ready."
            ))
            return venvPy
        } else {
            statusMessage = L(
                "自动安装本地连接依赖失败，请检查网络或执行 pip install -r requirements.txt。",
                "Failed to install local bridge dependencies. Check your network or run pip install -r requirements.txt."
            )
            return nil
        }
    }

    private func runBridgeCommand(_ args: [String], installIfMissing: Bool = false) async -> String {
        guard let pyBin = await ensureBridgePythonBin(installIfMissing: installIfMissing) else {
            return ""
        }
        let script = self.bridgeScript
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: pyBin)
                proc.arguments = [script] + args
                let pipe = Pipe()
                proc.standardOutput = pipe
                proc.standardError = pipe
                do {
                    try proc.run()
                    proc.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let out = String(data: data, encoding: .utf8) ?? ""
                    continuation.resume(returning: out.trimmingCharacters(in: .whitespacesAndNewlines))
                } catch {
                    continuation.resume(returning: "")
                }
            }
        }
    }

    func runDriveCommand(_ controller: DriveConnectionController, arguments: [String]) async {
        guard let python = await ensureBridgePythonBin(installIfMissing: true) else { return }
        controller.run(python: python, script: bridgeScript, arguments: arguments)
    }

    func refreshOfficialColabAccountUsage() async {
        let out = await runBridgeCommand(["auth_status"], installIfMissing: false)
        guard let data = out.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(BridgeAuthStatusResponse.self, from: data) else {
            return
        }
        cliLoggedIn = decoded.logged_in ?? false
        if let em = decoded.email, !em.isEmpty {
            accountEmail = em
        } else if !cliLoggedIn {
            accountEmail = ""
        }
        if let bal = decoded.paid_balance {
            officialCUBalance = bal
            totalBudgetCU = bal
        }
        if let rate = decoded.burn_rate_hourly { officialBurnRate = rate }
        if let count = decoded.active_assignments {
            activeVMCount = count
            if count == 0 && !isConnected && (!loadedModelsDetail.isEmpty || vramTotalGB > 0) {
                resetStaleRemoteRuntimeState(reason: L(
                    "云端 Colab 实例当前未运行，已自动清理历史显存状态；点击左侧「唤醒实例并部署」即可启动。",
                    "No active cloud Colab runtime detected; cleared stale VRAM state. Click 'Wake & Deploy' on the left to launch."
                ))
            }
        }
    }

    func startGoogleOAuthLogin(switchingAccount: Bool = false) async {
        let out = await runBridgeCommand(["auth_url"], installIfMissing: true)
        guard let data = out.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let authURLStr = json["auth_url"] as? String,
              let url = URL(string: authURLStr) else {
            if !statusMessage.contains("初始化") && !statusMessage.contains("Initializ") && !statusMessage.contains("Python") {
                statusMessage = L("获取 Google 授权链接失败", "Failed to obtain Google OAuth authorization URL")
            }
            return
        }
        oauthCodeText = ""
        showOAuthCodeInput = true
        NSWorkspace.shared.open(url)
        statusMessage = switchingAccount
            ? L("已在浏览器打开 Google 账号选择页，请选择新账号授权并粘贴授权码（点取消可保留原账号）。", "Opened Google account chooser in browser. Authorize a new account and paste the code (Cancel keeps current account).")
            : L("已在浏览器打开 Google 授权页，请允许访问后粘贴授权码。", "Opened Google authorization page in browser. Grant access and paste the auth code.")
    }

    func logoutGoogleAccount() async {
        _ = await runBridgeCommand(["auth_logout"], installIfMissing: false)
        cliLoggedIn = false
        accountEmail = ""
        showOAuthCodeInput = false
        oauthCodeText = ""
        officialCUBalance = nil
        officialBurnRate = nil
        activeVMCount = 0
        colabServerURL = ""
        resetStaleRemoteRuntimeState(reason: L(
            "已退出当前 Google 账号绑定；可点击左侧「绑定」登录其他账号。",
            "Signed out of Google account. Click 'Bind' on the left to sign in with another account."
        ))
    }

    func submitGoogleOAuthCode() async {
        let code = oauthCodeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        let prevEmail = accountEmail
        let wasLoggedIn = cliLoggedIn
        statusMessage = L("正在验证授权码并同步账户余额...", "Verifying authorization code & syncing CU balance...")
        let out = await runBridgeCommand(["auth_code", code], installIfMissing: true)
        guard let data = out.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(BridgeAuthStatusResponse.self, from: data) else {
            statusMessage = L("授权验证失败，请重试。", "Authorization verification failed. Please try again.")
            return
        }
        if decoded.logged_in == true {
            let newEmail = decoded.email ?? ""
            if wasLoggedIn && (prevEmail != newEmail || !colabServerURL.isEmpty) {
                colabServerURL = ""
                resetStaleRemoteRuntimeState(reason: "")
            }
            cliLoggedIn = true
            accountEmail = newEmail
            showOAuthCodeInput = false
            oauthCodeText = ""
            officialCUBalance = decoded.paid_balance
            officialBurnRate = decoded.burn_rate_hourly
            activeVMCount = decoded.active_assignments ?? 0
            if let bal = decoded.paid_balance {
                totalBudgetCU = bal
            }
            let emailTag = newEmail.isEmpty ? "" : " (\(displayAccountLabel))"
            statusMessage = L(
                "Google 账号绑定成功\(emailTag)！可用额度: \(String(format: "%.2f", decoded.paid_balance ?? 0)) CU",
                "Google account bound\(emailTag)! Available balance: \(String(format: "%.2f", decoded.paid_balance ?? 0)) CU"
            )
        } else {
            statusMessage = L(
                "授权码无效: \(decoded.error ?? "请重新获取")",
                "Invalid authorization code: \(decoded.error ?? "please generate a new code")"
            )
        }
    }

    @discardableResult
    func saveTunnelConfiguration() -> Bool {
        let token = cloudflareTunnelToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !customDomainURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !token.isEmpty else {
            tunnelCredentialMessage = L("请填写 HTTPS 域名和 Tunnel Token。", "Enter an HTTPS domain and Tunnel Token.")
            return false
        }
        do {
            try tunnelCredentialStore.save(token)
            cloudflareTunnelToken = token
            tunnelCredentialMessage = L("Token 已保存至本机钥匙串，下次启动自动读取。", "Token saved to this Mac's Keychain; restored on next launch.")
            return true
        } catch {
            tunnelCredentialMessage = L("Token 保存失败：请检查格式及钥匙串权限，未写入普通设置。", "Token not saved. Check its format and Keychain permissions; no plaintext fallback.")
            return false
        }
    }

    func clearSavedTunnelToken() {
        do {
            try tunnelCredentialStore.delete()
            cloudflareTunnelToken = ""
            tunnelCredentialMessage = L("已删除本地 Token，域名配置保留。", "Local token deleted; domain settings kept.")
        } catch {
            tunnelCredentialMessage = L("Token 删除失败，请检查钥匙串权限。", "Token deletion failed. Check Keychain permissions.")
        }
    }

    @discardableResult
    func saveHFToken() -> Bool {
        let token = hfToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else {
            hfCredentialMessage = L("请填写 HF Token；删除已保存凭据请点「清除」。", "Enter an HF Token; use Clear to delete saved credentials.")
            return false
        }
        do {
            try hfCredentialStore.save(token)
            hfToken = token
            hfCredentialMessage = L("HF Token 已保存至本机钥匙串，下次启动自动读取。", "HF Token saved to this Mac's Keychain; restored on next launch.")
            return true
        } catch {
            hfCredentialMessage = L("HF Token 保存失败，请检查格式和钥匙串权限；未写入普通配置。", "HF Token not saved. Check its format and Keychain permissions; no plaintext fallback.")
            return false
        }
    }

    func clearSavedHFToken() {
        do {
            try hfCredentialStore.delete()
            hfToken = ""
            hfCredentialMessage = L("已删除本地 HF Token，不影响 Tunnel Token；不会撤销 HF 网站上的令牌。", "Local HF Token deleted; Tunnel Token unchanged. The token is not revoked on Hugging Face.")
        } catch {
            hfCredentialMessage = L("HF Token 删除失败，请检查钥匙串权限。", "HF Token deletion failed. Check Keychain permissions.")
        }
    }

    func wakeColabHeadless() async {
        guard cliLoggedIn else {
            statusMessage = L("请先绑定 Google 账号后再使用免网页一键唤醒。", "Please bind your Google account before using headless 1-click wake.")
            return
        }
        if useCustomDomain && !saveTunnelConfiguration() {
            statusMessage = tunnelCredentialMessage
            return
        }
        isWakingColab = true
        statusMessage = L(
            "正在通过 Google Colab API 后台分配 \(wakeGPUChoice) 实例并部署多模型引擎...",
            "Provisioning \(wakeGPUChoice) runtime via Google Colab API & deploying multi-model engine..."
        )
        liveConsoleLines = [L(
            "[Colab-CLI] 正在启动免网页一键唤醒流程 (\(wakeGPUChoice) GPU)...",
            "[Colab-CLI] Starting headless 1-click wake (\(wakeGPUChoice) GPU)..."
        )]

        guard let pyBin = await ensureBridgePythonBin(installIfMissing: true) else {
            isWakingColab = false
            return
        }
        let script = self.bridgeScript
        let gpu = self.wakeGPUChoice
        let appPy = self.appPyPath
        var wakeEnvironment = ProcessInfo.processInfo.environment
        wakeEnvironment["EASYCOLAB_PUBLIC_URL"] = useCustomDomain ? customDomainURL : ""
        wakeEnvironment["CLOUDFLARE_TUNNEL_TOKEN"] = useCustomDomain ? cloudflareTunnelToken : ""
        let processEnvironment = wakeEnvironment

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: pyBin)
                proc.arguments = [script, "wake", "--gpu", gpu, "--app-py", appPy]
                proc.environment = processEnvironment
                let pipe = Pipe()
                proc.standardOutput = pipe
                proc.standardError = pipe

                pipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
                    let lines = chunk.components(separatedBy: .newlines)
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    Task { @MainActor in
                        for line in lines {
                            if line.hasPrefix("WAKE_URL:") {
                                let url = String(line.dropFirst("WAKE_URL:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                                self.colabServerURL = url
                                self.liveConsoleLines.append(L(
                                    "成功获取云端隧道地址: \(self.maskedURLDisplay(url))",
                                    "Obtained public tunnel URL: \(self.maskedURLDisplay(url))"
                                ))
                                self.statusMessage = L(
                                    "云端 \(gpu) 实例已唤醒就绪，正在同步模型状态...",
                                    "Cloud \(gpu) instance is ready. Syncing model status..."
                                )
                            } else if line.hasPrefix("WAKE_ERROR:") {
                                self.liveConsoleLines.append(line)
                                self.statusMessage = L("唤醒失败: \(line)", "Wake failed: \(line)")
                            } else {
                                let clean = line.replacingOccurrences(of: "WAKE_LOG: ", with: "")
                                self.liveConsoleLines.append(clean)
                                self.statusMessage = clean
                            }
                        }
                    }
                }

                do {
                    try proc.run()
                    proc.waitUntilExit()
                } catch {
                    Task { @MainActor in
                        self.statusMessage = L(
                            "启动唤醒进程失败: \(error.localizedDescription)",
                            "Failed to launch wake process: \(error.localizedDescription)"
                        )
                    }
                }
                pipe.fileHandleForReading.readabilityHandler = nil
                continuation.resume()
            }
        }

        isWakingColab = false
        await refreshOfficialColabAccountUsage()
        if !colabServerURL.isEmpty {
            await checkColabStatus()
        }
    }

    func keepaliveColabRuntime() async {
        guard cliLoggedIn, !isWakingColab else { return }
        let out = await runBridgeCommand(["keepalive"])
        guard let data = out.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(BridgeAuthStatusResponse.self, from: data) else {
            return
        }
        if let bal = decoded.paid_balance {
            officialCUBalance = bal
            totalBudgetCU = bal
        }
        if let rate = decoded.burn_rate_hourly { officialBurnRate = rate }
        if let count = decoded.active_assignments { activeVMCount = count }
    }

    func startBackgroundTelemetryLoop() {
        heartbeatTask?.cancel()
        heartbeatTask = Task {
            if !normalizedBaseURL.isEmpty {
                await checkColabStatus(silent: true)
            }
            var tick = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                tick += 1
                if isConnected {
                    // 生成任务进行中由 pollColabJob 附带 telemetry 实时更新图表，仅每 15s 低频同步一次全局状态，避免争抢 Gradio 隧道
                    if !isGenerating || tick % 6 == 0 {
                        await checkColabStatus(silent: true)
                    }
                } else if !normalizedBaseURL.isEmpty && tick % 4 == 0 {
                    await checkColabStatus(silent: true)
                }

                // 每 ~80 秒：若处于生成任务或活跃保活窗口内，向 Colab 官方 Runtime Proxy 发送轻量保活脉冲，杜绝生成第 2 条视频中途被回收
                if tick % 32 == 0 && cliLoggedIn && !isWakingColab {
                    let shouldKeepalive = isConnected && (
                        isGenerating
                        || isDownloadingWeights
                        || isLoadingModel
                        || comfyStarting
                        || comfyDownloadingWeight
                        || comfyQueueRunning > 0
                        || idleTimeoutMinutes <= 0
                        || idleRemainingSeconds > 75
                    )
                    if shouldKeepalive {
                        await keepaliveColabRuntime()
                    } else {
                        await refreshOfficialColabAccountUsage()
                    }
                } else if tick % 16 == 0 && cliLoggedIn && !isConnected {
                    await refreshOfficialColabAccountUsage()
                }
            }
        }
    }

    // MARK: - 本地历史媒体库（支持 MP4 视频与 PNG/JPG 图片，兼容旧目录）
    func refreshLocalMedia() {
        var allURLs: [URL] = []
        for dir in [localSaveDir] + legacySaveDirs {
            if let urls = try? FileManager.default.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            ) {
                allURLs.append(contentsOf: urls)
            }
        }

        let validExts: Set<String> = ["mp4", "png", "jpg", "jpeg", "webp"]
        var seenNames = Set<String>()
        let filtered = allURLs.filter { url in
            guard validExts.contains(url.pathExtension.lowercased()) else { return false }
            return seenNames.insert(url.lastPathComponent).inserted
        }
        let items: [LocalMediaItem] = filtered.compactMap { url in
            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
            let date = (attrs?[.creationDate] as? Date) ?? Date.distantPast
            let ext = url.pathExtension.lowercased()
            let fname = url.lastPathComponent
            return LocalMediaItem(
                url: url,
                filename: fname,
                isImage: ext != "mp4",
                createdAt: date,
                elapsedSeconds: mediaElapsedMap[fname]
            )
        }.sorted(by: { $0.createdAt > $1.createdAt })

        self.localMediaItems = items
        if currentMediaURL == nil, let first = items.first {
            selectMedia(first.url)
        }
    }

    func selectMedia(_ url: URL) {
        currentMediaURL = url
        let ext = url.pathExtension.lowercased()
        if ext == "mp4" {
            currentPreviewImage = nil
            player = AVPlayer(url: url)
            player?.play()
        } else {
            player?.pause()
            player = nil
            currentPreviewImage = NSImage(contentsOf: url)
        }
    }

    private func applyStatusResponse(_ decoded: ColabStatusResponse) {
        let recovering = !isConnected && connectionWarning != nil && statusMessage == connectionWarning
        let taskWasBusy = isLoadingModel || isDownloadingWeights
        statusSuccessVersion &+= 1
        consecutiveStatusFailures = 0
        isConnected = true
        cpuUtilization = decoded.cpu_utilization_pct
        gpuUtilization = decoded.gpu_utilization_pct
        gpuName = decoded.gpu_name ?? "Colab GPU"
        vramFreeGB = decoded.vram_free_gb ?? 0.0
        vramTotalGB = decoded.vram_total_gb ?? 0.0
        vramUsedGB = decoded.vram_used_gb ?? 0.0
        ramTotalGB = decoded.ram_total_gb ?? ramTotalGB
        ramUsedGB = decoded.ram_used_gb ?? ramUsedGB
        ramFreeGB = decoded.ram_free_gb ?? ramFreeGB
        diskTotalGB = decoded.disk_total_gb ?? diskTotalGB
        diskUsedGB = decoded.disk_used_gb ?? diskUsedGB
        diskFreeGB = decoded.disk_free_gb ?? diskFreeGB
        shmTotalGB = decoded.shm_total_gb ?? shmTotalGB
        shmUsedGB = decoded.shm_used_gb ?? shmUsedGB
        shmFreeGB = decoded.shm_free_gb ?? shmFreeGB
        driveTotalGB = decoded.drive_total_gb ?? driveTotalGB
        driveUsedGB = decoded.drive_used_gb ?? driveUsedGB
        driveFreeGB = decoded.drive_free_gb ?? driveFreeGB
        recordTelemetrySample()
        loadedModelId = decoded.loaded_model_id
        if let ids = decoded.loaded_model_ids {
            loadedModelIds = ids
        } else if let single = decoded.loaded_model_id, decoded.model_loaded == true {
            loadedModelIds = [single]
        } else if decoded.any_model_loaded == false {
            loadedModelIds = []
        }
        if let details = decoded.loaded_models_detail {
            loadedModelsDetail = details.map { item in
                var clean = item
                clean.name = stripEmoji(item.name)
                if let m = item.mode { clean.mode = stripEmoji(m) }
                return clean
            }
        } else if decoded.any_model_loaded == false {
            loadedModelsDetail = []
        }
        modelLoaded = loadedModelIds.contains(selectedModelId) || (decoded.model_loaded ?? false)
        currentModelName = decoded.current_model ?? L(Self.defaultModelNameZh, Self.defaultModelNameEn)
        loadedContextLengthTokens = decoded.loaded_context_length ?? 0

        if !remoteContextSynced {
            remoteContextSynced = true
            if let remoteCtx = decoded.context_length, remoteCtx != contextLengthTokens {
                Task { await syncContextLengthToColab() }
            }
        }

        if let files = decoded.files, !files.isEmpty {
            modelFiles = files
        }
        downloadedCount = decoded.downloaded_count ?? downloadedCount
        totalFileCount = decoded.total_count ?? activeModelSpec.defaultFiles.count
        allDownloaded = decoded.all_downloaded ?? (downloadedCount == totalFileCount && totalFileCount > 0)
        totalDiskSizeGB = decoded.total_size_gb ?? totalDiskSizeGB
        drivePersisted = decoded.drive_persisted ?? false
        bf16ShardsCount = decoded.bf16_shards_count ?? 0
        isDownloadingWeights = decoded.is_downloading ?? false
        isLoadingModel = decoded.is_loading_vram ?? false
        if let p = decoded.task_progress { modelTaskProgress = p }
        let taskEnded = taskWasBusy && !isLoadingModel && !isDownloadingWeights
        if recovering || (connectionWarning != nil && statusMessage == connectionWarning) || taskEnded {
            if let message = decoded.task_message, !message.isEmpty, taskWasBusy || isLoadingModel || isDownloadingWeights {
                statusMessage = message
            } else if !isGenerating {
                statusMessage = modelLoaded
                    ? L("连接已恢复 · 模型已就绪，可以开始对话或生成。", "Connection restored · model ready for chat or generation.")
                    : L("已连接云端 · 状态已同步。", "Connected · cloud status synchronized.")
            }
        }
        connectionWarning = nil
        downloadCompletedBytes = decoded.download_completed_bytes ?? 0
        downloadTotalBytes = decoded.download_total_bytes ?? 0
        uploadCompletedBytes = decoded.upload_completed_bytes ?? 0
        uploadConfirmedBytes = decoded.upload_confirmed_bytes ?? 0
        uploadTotalBytes = decoded.upload_total_bytes ?? 0
        uploadState = decoded.upload_state ?? ""
        uploadLive = decoded.upload_live ?? false
        transferMessage = decoded.transfer_message ?? ""

        uptimeSeconds = decoded.uptime_seconds ?? uptimeSeconds
        cuBurnRatePerHour = decoded.cu_burn_rate_per_hour ?? cuBurnRatePerHour
        sessionCUUsed = decoded.session_cu_used ?? sessionCUUsed
        idleRemainingSeconds = decoded.idle_remaining_seconds ?? idleRemainingSeconds
        if !remoteIdleSynced {
            remoteIdleSynced = true
            if let remoteIdle = decoded.idle_timeout_minutes, remoteIdle != idleTimeoutMinutes {
                Task { await updateIdleTimeoutConfig(idleTimeoutMinutes) }
            }
        }
        apiRequestCount = decoded.api_request_count ?? apiRequestCount
        let remoteHasKey = decoded.api_key_enabled ?? false
        if apiKeyEnabled && !remoteHasKey && !remoteApiKeySynced {
            remoteApiKeySynced = true
            Task { await syncApiKeyToColab() }
        }
        if let lines = decoded.console_lines, !lines.isEmpty {
            liveConsoleLines = lines
        }
        if let cf = decoded.comfyui {
            comfyRunning = cf.is_running ?? false
            comfyStarting = cf.is_starting ?? false
            comfySyncingDrive = cf.is_syncing_drive ?? false
            comfyDownloadingWeight = cf.is_downloading_weight ?? false
            comfyInstallingPackId = cf.installing_pack_id ?? ""
            comfyProgress = cf.progress ?? 0.0
            if let sm = cf.status_message, !sm.isEmpty {
                comfyStatusMessage = sm
            }
            comfyPublicURL = cf.public_url ?? ""
            comfyQueueRunning = cf.queue_running ?? 0
            comfyQueuePending = cf.queue_pending ?? 0
            if let pl = cf.persistence_label, !pl.isEmpty {
                comfyPersistenceLabel = pl
            }
            comfyDrivePersisted = cf.drive_persisted ?? drivePersisted
            if let pr = cf.persist_root, !pr.isEmpty {
                comfyPersistRoot = pr
            }
            comfyCustomNodesCount = cf.custom_nodes_count ?? 0
            comfyModelsCount = cf.models_count ?? 0
            comfyWorkflowsCount = cf.workflows_count ?? 0
            if let outs = cf.recent_outputs {
                comfyRecentOutputs = outs
            }
            if let packs = cf.preset_packs, !packs.isEmpty {
                comfyPresetPacks = packs
            }
        }
    }

    func openComfyUIInBrowser() {
        guard let url = URL(string: comfyPublicURL), !comfyPublicURL.isEmpty else { return }
        NSWorkspace.shared.open(url)
    }

    func startRemoteComfyUI(forceRestart: Bool = false, autoOpenBrowser: Bool = true) async {
        let base = normalizedBaseURL
        guard isConnected, !base.isEmpty, let url = URL(string: "\(base)/minimax_api/comfyui/start") else {
            statusMessage = L(
                "请先唤醒或连接云端 G4 实例后再启动 ComfyUI。",
                "Please wake or connect to a cloud G4 instance before starting ComfyUI."
            )
            return
        }
        comfyStarting = true
        comfyProgress = 0.04
        let tip = forceRestart
            ? L("正在重启云端 ComfyUI 并重新加载自定义节点...", "Restarting cloud ComfyUI & reloading custom nodes...")
            : L("正在部署云端 ComfyUI 并挂载 Google Drive 持久化软链...", "Deploying cloud ComfyUI & mounting Google Drive persistence symlinks...")
        comfyStatusMessage = tip
        statusMessage = tip

        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.timeoutInterval = 30
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: [
                "unload_existing": comfyUnloadOthersOnStart,
                "force_restart": forceRestart
            ])
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode(ColabStatusResponse.self, from: data)
            applyStatusResponse(decoded)

            // 持续轮询直到启动完成并拿到 trycloudflare 公网画布地址
            for _ in 0..<180 {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await checkColabStatus(silent: true)
                statusMessage = comfyStatusMessage
                if comfyRunning && !comfyPublicURL.isEmpty && !comfyStarting {
                    statusMessage = L(
                        "ComfyUI 全屏节点工作台已就绪！正在为您在浏览器中打开画布...",
                        "ComfyUI fullscreen node canvas is ready! Opening in your browser..."
                    )
                    if autoOpenBrowser {
                        openComfyUIInBrowser()
                    }
                    return
                }
                if !comfyStarting && !comfyRunning {
                    break
                }
            }
        } catch {
            comfyStarting = false
            statusMessage = L(
                "启动 ComfyUI 请求失败: \(error.localizedDescription)",
                "Failed to start ComfyUI: \(error.localizedDescription)"
            )
        }
    }

    func stopRemoteComfyUI() async {
        let base = normalizedBaseURL
        guard isConnected, !base.isEmpty, let url = URL(string: "\(base)/minimax_api/comfyui/stop") else { return }
        statusMessage = L(
            "正在同步自定义节点与工作流到 Google Drive 并停止 ComfyUI...",
            "Syncing custom nodes & workflows to Google Drive and stopping ComfyUI..."
        )
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.timeoutInterval = 35
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode(ColabStatusResponse.self, from: data)
            applyStatusResponse(decoded)
            statusMessage = comfyStatusMessage
        } catch {
            statusMessage = L(
                "停止 ComfyUI 失败: \(error.localizedDescription)",
                "Failed to stop ComfyUI: \(error.localizedDescription)"
            )
        }
    }

    func freeRemoteComfyUIVRAM() async {
        let base = normalizedBaseURL
        guard isConnected, !base.isEmpty, let url = URL(string: "\(base)/minimax_api/comfyui/free_vram") else { return }
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.timeoutInterval = 20
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode(ColabStatusResponse.self, from: data)
            applyStatusResponse(decoded)
            if let am = decoded.action_message, !am.isEmpty {
                statusMessage = am
            }
        } catch {}
    }

    func syncRemoteComfyUIToDrive() async {
        let base = normalizedBaseURL
        guard isConnected, !base.isEmpty, let url = URL(string: "\(base)/minimax_api/comfyui/sync_drive") else { return }
        comfySyncingDrive = true
        statusMessage = L(
            "正在将 ComfyUI 自定义节点、模型与工作流同步至 Google Drive...",
            "Syncing ComfyUI custom nodes, models & workflows to Google Drive..."
        )
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.timeoutInterval = 90
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode(ColabStatusResponse.self, from: data)
            applyStatusResponse(decoded)
            if let am = decoded.action_message, !am.isEmpty {
                statusMessage = am
            }
        } catch {
            comfySyncingDrive = false
            statusMessage = L(
                "同步至 Google Drive 失败: \(error.localizedDescription)",
                "Failed to sync to Google Drive: \(error.localizedDescription)"
            )
        }
    }

    func startComfyWeightDownload() async {
        if !hfToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { saveHFToken() }
        let src = comfyWeightSourceInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !src.isEmpty else {
            statusMessage = L(
                "请先粘贴 HuggingFace 模型直链、下载 URL 或 仓库 ID",
                "Please paste a Hugging Face direct link, download URL, or repo ID first"
            )
            return
        }
        let base = normalizedBaseURL
        guard isConnected, !base.isEmpty, let url = URL(string: "\(base)/minimax_api/comfyui/download_weight") else {
            statusMessage = L("请先连接 Colab 实例后再下载权重", "Please connect to a Colab instance before downloading weights")
            return
        }
        comfyDownloadingWeight = true
        comfyProgress = 0.05
        statusMessage = L(
            "正在通过云端 8 线程通道下载权重至 ComfyUI/models/\(comfyWeightSubfolder)...",
            "Downloading weights via 8-thread cloud channel to ComfyUI/models/\(comfyWeightSubfolder)..."
        )
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.timeoutInterval = 25
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: [
                "url_or_repo": src,
                "filename": comfyWeightFilenameInput.trimmingCharacters(in: .whitespacesAndNewlines),
                "subfolder": comfyWeightSubfolder,
                "hf_token": hfToken.trimmingCharacters(in: .whitespacesAndNewlines)
            ])
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode(ColabStatusResponse.self, from: data)
            applyStatusResponse(decoded)

            while comfyDownloadingWeight {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await checkColabStatus(silent: true)
                statusMessage = comfyStatusMessage
            }
        } catch {
            comfyDownloadingWeight = false
            statusMessage = L(
                "提交权重下载失败: \(error.localizedDescription)",
                "Failed to start weight download: \(error.localizedDescription)"
            )
        }
    }

    func installComfyPresetPack(_ pack: ComfyPresetPackItem, openWhenReady: Bool = true) async {
        if !hfToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { saveHFToken() }
        let base = normalizedBaseURL
        guard isConnected, !base.isEmpty, let url = URL(string: "\(base)/minimax_api/comfyui/install_pack") else {
            statusMessage = L(
                "请先在左侧唤醒或连接云端 G4 实例后再一键配齐工作流包。",
                "Please wake or connect to a cloud G4 instance on the left before installing a workflow pack."
            )
            return
        }
        comfyDownloadingWeight = true
        comfyInstallingPackId = pack.id
        comfyProgress = 0.04
        let tip = L(
            "正在为您一键配齐「\(pack.localizedTitle)」模型权重与全中文工作流...",
            "Installing models & workflow templates for \"\(pack.localizedTitle)\"..."
        )
        comfyStatusMessage = tip
        statusMessage = tip

        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.timeoutInterval = 30
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: [
                "pack_id": pack.id,
                "auto_start": true,
                "hf_token": hfToken.trimmingCharacters(in: .whitespacesAndNewlines)
            ])
            let (data, resp) = try await URLSession.shared.data(for: req)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if code == 404 {
                comfyDownloadingWeight = false
                comfyInstallingPackId = ""
                let upgradeTip = L(
                    "当前云端实例仍在运行旧版服务，请点左侧「唤醒实例并部署」热更新服务端（不会释放现有 G4 实例与画布），随后即可一键配齐工作流！",
                    "The cloud instance is running an older server version. Click 'Wake & Deploy' on the left to hot-update app.py without releasing your G4 VM, then install the pack!"
                )
                comfyStatusMessage = upgradeTip
                statusMessage = upgradeTip
                return
            }
            let decoded = try JSONDecoder().decode(ColabStatusResponse.self, from: data)
            applyStatusResponse(decoded)

            for _ in 0..<600 {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await checkColabStatus(silent: true)
                statusMessage = comfyStatusMessage
                if !comfyDownloadingWeight && comfyInstallingPackId.isEmpty && !comfyStarting {
                    break
                }
            }
            if openWhenReady && comfyRunning && !comfyPublicURL.isEmpty {
                openComfyUIInBrowser()
            }
        } catch {
            comfyDownloadingWeight = false
            comfyInstallingPackId = ""
            statusMessage = L(
                "一键配齐预置工作流包失败: \(error.localizedDescription)",
                "Failed to install preset workflow pack: \(error.localizedDescription)"
            )
        }
    }

    func downloadComfyOutputToMac(_ item: ComfyOutputMediaItem) async {
        let base = normalizedBaseURL
        let encodedRel = item.rel_path
            .split(separator: "/")
            .map { $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }
            .joined(separator: "/")
        guard !base.isEmpty, let url = URL(string: "\(base)/minimax_api/comfyui/output_media/\(encodedRel)") else { return }
        comfyPullingOutputRelPath = item.rel_path
        statusMessage = L(
            "正在从 ComfyUI 云端输出目录拉取 \(item.filename) 到本地 Mac...",
            "Pulling \(item.filename) from ComfyUI cloud output folder to Mac..."
        )
        defer { comfyPullingOutputRelPath = nil }
        do {
            let (tmpURL, resp) = try await URLSession.shared.download(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
                statusMessage = L(
                    "拉取成片失败: 云端文件不存在或尚未写入完成",
                    "Failed to pull output: remote file does not exist or is still being written"
                )
                return
            }
            let safeName = "comfy_" + (item.filename as NSString).lastPathComponent
            let dstURL = localSaveDir.appendingPathComponent(safeName)
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try? FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.moveItem(at: tmpURL, to: dstURL)
            refreshLocalMedia()
            let ext = dstURL.pathExtension.lowercased()
            currentMediaURL = dstURL
            if ["png", "jpg", "jpeg", "webp", "gif"].contains(ext), let img = NSImage(contentsOf: dstURL) {
                player?.pause()
                player = nil
                currentPreviewImage = img
            } else {
                currentPreviewImage = nil
                player = AVPlayer(url: dstURL)
                player?.play()
            }
            statusMessage = L(
                "已将 ComfyUI 成片保存至本地目录: \(dstURL.lastPathComponent)",
                "Saved ComfyUI output to local folder: \(dstURL.lastPathComponent)"
            )
        } catch {
            statusMessage = L(
                "下载 ComfyUI 成片失败: \(error.localizedDescription)",
                "Failed to download ComfyUI output: \(error.localizedDescription)"
            )
        }
    }

    func regenerateApiKey() {
        apiAccessKey = "sk-colab-" + UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(20).lowercased()
        Task { await syncApiKeyToColab() }
    }

    func syncApiKeyToColab() async {
        let base = normalizedBaseURL
        guard isConnected, !base.isEmpty, let url = URL(string: "\(base)/minimax_api/config_api_key") else { return }
        let payloadKey = apiKeyEnabled ? apiAccessKey.trimmingCharacters(in: .whitespacesAndNewlines) : ""
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: ["api_key": payloadKey])
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode(ColabStatusResponse.self, from: data)
            remoteApiKeySynced = true
            applyStatusResponse(decoded)
        } catch {}
    }

    func syncContextLengthToColab(announce: Bool = false) async {
        let base = normalizedBaseURL
        guard isConnected, !base.isEmpty, let url = URL(string: "\(base)/minimax_api/config_context") else { return }
        let targetTokens = contextLengthTokens
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: ["context_length": targetTokens])
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode(ColabStatusResponse.self, from: data)
            remoteContextSynced = true
            applyStatusResponse(decoded)
            if announce, let msg = decoded.task_message, !msg.isEmpty {
                statusMessage = msg
            }
        } catch {}
    }

    func checkColabStatus(silent: Bool = false) async {
        let successVersion = statusSuccessVersion
        let base = normalizedBaseURL
        guard !base.isEmpty,
              let url = URL(string: "\(base)/minimax_api/status?model_id=\(selectedModelId)") else {
            if !silent {
                statusMessage = L(
                    "请先填入服务地址，或点击左侧「唤醒实例并部署」。",
                    "Please enter a Server URL, or click 'Wake & Deploy' on the left."
                )
            }
            isConnected = false
            return
        }

        if !silent {
            statusMessage = L(
                "正在同步 Colab GPU 显存与 \(activeModelSpec.name) 权重状态...",
                "Syncing Colab GPU VRAM & \(activeModelSpec.name) weight status..."
            )
        }
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = isGenerating ? 28 : (silent ? 20 : 22)
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard base == normalizedBaseURL else { return }
            let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if statusCode != 200 && successVersion != statusSuccessVersion { return }

            if statusCode == 404 {
                // 生成视频高负载期间单次 404 可能为 Gradio FRP 隧道瞬断，需连续多次确认才判定进程已停止
                consecutiveStatusFailures += (isGenerating ? 1 : 2)
                if !silent || consecutiveStatusFailures >= 6 {
                    consecutiveStatusFailures = 0
                    resetStaleRemoteRuntimeState(
                        reason: L(
                            "云端 Colab 推理服务已停止（可能因显存溢出或实例释放），已自动重置本地显存状态；请点击左侧「唤醒实例并部署」重新启动。",
                            "Cloud Colab server has stopped (OOM or runtime released). Local VRAM state reset; click 'Wake & Deploy' on the left to restart."
                        )
                    )
                }
                return
            }

            guard statusCode == 200 else {
                consecutiveStatusFailures += 1
                let failureLimit = isGenerating ? 8 : 5
                if !silent || consecutiveStatusFailures >= failureLimit {
                    resetStaleRemoteRuntimeState(
                        reason: L(
                            "无法连接至 Colab 服务端 (HTTP \(statusCode))，实例可能已关闭或网络中断。",
                            "Unable to reach Colab server (HTTP \(statusCode)). Runtime may be stopped or network disconnected."
                        )
                    )
                }
                return
            }

            consecutiveStatusFailures = 0
            let decoded = try JSONDecoder().decode(ColabStatusResponse.self, from: data)
            applyStatusResponse(decoded)

            if !silent {
                if (isLoadingModel || isDownloadingWeights), let message = decoded.task_message, !message.isEmpty {
                    statusMessage = message
                } else if isSelectedModelLoadedInVRAM {
                    statusMessage = L(
                        "已连接 \(gpuName) | \(activeModelSpec.name) 已驻留显存，可立即开始生成！",
                        "Connected to \(gpuName) | \(activeModelSpec.name) is in VRAM and ready to generate!"
                    )
                } else if allDownloaded {
                    statusMessage = L(
                        "已连接 \(gpuName) | \(activeModelSpec.name) 权重已就绪 (\(String(format: "%.1f", totalDiskSizeGB)) GB)，请点击「加载到显存」。",
                        "Connected to \(gpuName) | \(activeModelSpec.name) weights ready (\(String(format: "%.1f", totalDiskSizeGB)) GB). Click 'Load to VRAM'."
                    )
                } else {
                    statusMessage = L(
                        "已连接 \(gpuName) | \(activeModelSpec.name) 权重进度 \(downloadedCount)/\(totalFileCount)，请先点击「下载权重」。",
                        "Connected to \(gpuName) | \(activeModelSpec.name) weights \(downloadedCount)/\(totalFileCount). Click 'Download Weights' first."
                    )
                }
            }
        } catch {
            guard successVersion == statusSuccessVersion, base == normalizedBaseURL else { return }
            consecutiveStatusFailures += 1
            let failureLimit = isGenerating ? 8 : 5
            if !silent {
                resetStaleRemoteRuntimeState(reason: L(
                    "连接失败: \(error.localizedDescription)",
                    "Connection failed: \(error.localizedDescription)"
                ))
            } else if consecutiveStatusFailures >= failureLimit && isConnected {
                resetStaleRemoteRuntimeState(
                    reason: L(
                        "与 Colab 服务端连接中断，已重置本地常驻状态；可点击「连接」重试或「唤醒实例并部署」。",
                        "Disconnected from Colab server; local VRAM state reset. Click 'Connect' to retry or 'Wake & Deploy'."
                    )
                )
            }
        }
    }

    func updateIdleTimeoutConfig(_ minutes: Int) async {
        idleTimeoutMinutes = minutes
        let base = normalizedBaseURL
        guard isConnected, !base.isEmpty, let url = URL(string: "\(base)/minimax_api/config_idle") else { return }
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: ["idle_timeout_minutes": minutes])
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode(ColabStatusResponse.self, from: data)
            applyStatusResponse(decoded)
        } catch {}
    }

    func startRemoteDownloadWeights() async {
        if !hfToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { saveHFToken() }
        let base = normalizedBaseURL
        guard !base.isEmpty, let url = URL(string: "\(base)/minimax_api/download_model") else {
            statusMessage = L("请先连接有效的 Colab 服务端地址。", "Please connect to a valid Colab Server URL first.")
            return
        }

        let targetModel = selectedModelId
        isDownloadingWeights = true
        modelTaskProgress = 0.05
        statusMessage = L(
            "已通知 Colab 启动 8 线程并发下载 \(activeModelSpec.name)...",
            "Started 8-thread parallel weight download on Colab for \(activeModelSpec.name)..."
        )

        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: [
                "model_id": targetModel,
                "hf_token": hfToken
            ])
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode(ColabStatusResponse.self, from: data)
            applyStatusResponse(decoded)

            while isDownloadingWeights {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                if let statusURL = URL(string: "\(base)/minimax_api/status?model_id=\(targetModel)"),
                   let (sData, _) = try? await URLSession.shared.data(from: statusURL),
                   let sDecoded = try? JSONDecoder().decode(ColabStatusResponse.self, from: sData) {
                    applyStatusResponse(sDecoded)
                    if let msg = sDecoded.task_message, !msg.isEmpty { statusMessage = msg }
                    if !(sDecoded.is_downloading ?? false) {
                        isDownloadingWeights = false
                        break
                    }
                }
            }
        } catch {
            isDownloadingWeights = false
            statusMessage = L(
                "下载权重请求失败: \(error.localizedDescription)",
                "Weight download request failed: \(error.localizedDescription)"
            )
        }
    }

    func loadRemoteModelToVRAM() async {
        if !hfToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { saveHFToken() }
        let base = normalizedBaseURL
        guard !base.isEmpty, let url = URL(string: "\(base)/minimax_api/load_model") else {
            statusMessage = L("请先填入有效的 Colab 服务端地址。", "Please enter a valid Colab Server URL first.")
            return
        }

        if !allDownloaded {
            statusMessage = L(
                "\(activeModelSpec.name) 权重尚未下载完整 (\(downloadedCount)/\(totalFileCount))，请先点击「下载权重」。",
                "\(activeModelSpec.name) weights are incomplete (\(downloadedCount)/\(totalFileCount)). Click 'Download Weights' first."
            )
            return
        }

        let targetModel = selectedModelId
        isLoadingModel = true
        modelTaskProgress = 0.15
        if activeModelSpec.modality == .llmVLM {
            statusMessage = L(
                "正在将 \(activeModelSpec.name) 装载进 Colab GPU 显存 (上下文 \(contextLengthK)K)...",
                "Loading \(activeModelSpec.name) into Colab GPU VRAM (Context \(contextLengthK)K)..."
            )
        } else {
            statusMessage = L(
                "正在将 \(activeModelSpec.name) 装载进 Colab GPU 显存...",
                "Loading \(activeModelSpec.name) into Colab GPU VRAM..."
            )
        }

        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = [
                "model_id": targetModel,
                "precision_mode": targetModel == "qwen38_flash_next_nvfp4" ? "nvfp4" : "bf16",
                "offload_mode": selectedOffload,
                "context_length": contextLengthTokens,
                "hf_token": hfToken
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode(ColabStatusResponse.self, from: data)
            applyStatusResponse(decoded)

            while isLoadingModel {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                if let statusURL = URL(string: "\(base)/minimax_api/status?model_id=\(targetModel)"),
                   let (sData, _) = try? await URLSession.shared.data(from: statusURL),
                   let sDecoded = try? JSONDecoder().decode(ColabStatusResponse.self, from: sData) {
                    applyStatusResponse(sDecoded)
                    if let msg = sDecoded.task_message, !msg.isEmpty { statusMessage = msg }
                    if !(sDecoded.is_loading_vram ?? false) {
                        isLoadingModel = false
                        break
                    }
                }
            }
        } catch {
            isLoadingModel = false
            statusMessage = L(
                "加载模型请求失败: \(error.localizedDescription)",
                "Load model request failed: \(error.localizedDescription)"
            )
        }
    }

    func unloadRemoteModelFromVRAM(modelId: String) async {
        let targetLabel = modelId == "all"
            ? L("全部常驻模型", "all resident models")
            : (OPEN_MODEL_CATALOG.first(where: { $0.id == modelId })?.name ?? modelId)

        if modelId == "all" || modelId == selectedModelId {
            isGenerating = false
            progressValue = 0.0
        }

        let base = normalizedBaseURL
        guard !base.isEmpty, let url = URL(string: "\(base)/minimax_api/unload_model") else {
            clearLocalLoadedModelRecord(modelId)
            statusMessage = L(
                "已清理本地 \(targetLabel) 常驻记录。",
                "Cleared local VRAM residency record for \(targetLabel)."
            )
            return
        }

        isUnloadingModel = true
        defer { isUnloadingModel = false }
        statusMessage = L(
            "正在中断关联任务并从 GPU 显存卸载 \(targetLabel)...",
            "Interrupting related tasks and unloading \(targetLabel) from GPU VRAM..."
        )

        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.timeoutInterval = 20
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: ["model_id": modelId])
            let (data, resp) = try await URLSession.shared.data(for: req)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if code == 200 {
                let decoded = try JSONDecoder().decode(ColabStatusResponse.self, from: data)
                applyStatusResponse(decoded)
                if let msg = decoded.task_message, !msg.isEmpty {
                    statusMessage = msg
                } else {
                    statusMessage = L(
                        "已从显存卸载 \(targetLabel)，当前可用显存 \(String(format: "%.1f", vramFreeGB)) GB。",
                        "Unloaded \(targetLabel) from VRAM. Free VRAM: \(String(format: "%.1f", vramFreeGB)) GB."
                    )
                }
            } else {
                // 远端已离线或 404，直接清理本地残留状态，绝不卡死按钮
                resetStaleRemoteRuntimeState(reason: L(
                    "远端 Colab 服务已停止，已清理本地 \(targetLabel) 显存记录。",
                    "Remote Colab server stopped; cleared local VRAM record for \(targetLabel)."
                ))
            }
        } catch {
            clearLocalLoadedModelRecord(modelId)
            if !isConnected {
                resetStaleRemoteRuntimeState(reason: L(
                    "远端实例未连接，已移除本地 \(targetLabel) 常驻记录。",
                    "Remote instance disconnected; removed local VRAM record for \(targetLabel)."
                ))
            } else {
                statusMessage = L(
                    "远端响应超时，已先移除本地 \(targetLabel) 常驻状态 (\(error.localizedDescription))。",
                    "Remote timed out; cleared local VRAM record for \(targetLabel) (\(error.localizedDescription))."
                )
            }
        }
    }

    func cancelCurrentGeneration() async {
        activeGenerationToken = UUID()
        stopLiveGenerationTimer()
        isGenerating = false
        progressValue = 0.0
        currentJobElapsed = 0.0
        stripConsoleProgressBars()
        statusMessage = L(
            "已发送停止指令，正在中断云端 GPU 推理任务...",
            "Stop signal sent. Aborting cloud GPU inference..."
        )

        let base = normalizedBaseURL
        guard !base.isEmpty, let url = URL(string: "\(base)/minimax_api/cancel") else { return }
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.timeoutInterval = 12
            let (data, resp) = try await URLSession.shared.data(for: req)
            if (resp as? HTTPURLResponse)?.statusCode == 200,
               let decoded = try? JSONDecoder().decode(ColabStatusResponse.self, from: data) {
                applyStatusResponse(decoded)
            }
            stripConsoleProgressBars()
            statusMessage = L(
                "已停止当前推理任务，GPU 已恢复就绪。",
                "Stopped current inference task. GPU is ready."
            )
        } catch {
            statusMessage = L(
                "本地已停止；远端连接异常: \(error.localizedDescription)",
                "Stopped locally; remote connection error: \(error.localizedDescription)"
            )
        }
    }

    func startGeneration() async {
        let promptTrimmed = visualPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !promptTrimmed.isEmpty else {
            statusMessage = activeModelSpec.modality == .llmVLM
                ? L("请输入对话问题或视觉指令！", "Please enter a question or vision prompt!")
                : L("请输入画面描述提示词！", "Please enter a visual scene prompt!")
            return
        }

        if taskModeId == "fl2va" && firstFrameImage == nil && lastFrameImage == nil {
            statusMessage = L(
                "在「首尾帧生视频」模式下，请至少提供一张首帧或尾帧图片。",
                "In First/Last Frame mode, please provide at least a start frame or end frame image."
            )
            return
        }
        if taskModeId == "i2v" && firstFrameImage == nil {
            statusMessage = L(
                "在「首帧图生视频」模式下，请提供一张首帧图片。",
                "In Image-to-Video mode, please provide a start frame image."
            )
            return
        }
        if taskModeId == "i2i_edit" && firstFrameImage == nil && lastFrameImage == nil {
            statusMessage = L(
                "在「图像编辑/重绘」模式下，请至少拖入一张参考原图。",
                "In Image Edit / Restyle mode, please drop at least one reference image."
            )
            return
        }

        await checkColabStatus(silent: true)
        guard isConnected else {
            statusMessage = L(
                "尚未连接 Colab 服务端，请先唤醒或连接现有实例。",
                "Not connected to Colab server. Please wake & deploy or connect to an active runtime first."
            )
            return
        }
        guard isSelectedModelLoadedInVRAM else {
            if !allDownloaded {
                statusMessage = L(
                    "请先在左侧点击「下载权重」，再点击「加载到显存」装载 \(activeModelSpec.name)。",
                    "Click 'Download Weights' first, then 'Load to VRAM' to load \(activeModelSpec.name)."
                )
            } else {
                statusMessage = L(
                    "\(activeModelSpec.name) 尚未装载至显存，请先点击左侧「加载到显存」。",
                    "\(activeModelSpec.name) is not in VRAM yet. Click 'Load to VRAM' on the left first."
                )
            }
            return
        }

        let base = normalizedBaseURL
        guard let submitURL = URL(string: "\(base)/minimax_api/generate") else { return }

        let myToken = UUID()
        activeGenerationToken = myToken
        isGenerating = true
        progressValue = 0.0
        currentJobElapsed = 0.0
        stripConsoleProgressBars()
        startLiveGenerationTimer()
        statusMessage = L(
            "正在向 Colab 提交 \(activeModelSpec.name) 推理任务 (0%)...",
            "Submitting \(activeModelSpec.name) inference job to Colab (0%)..."
        )

        let resOpt = activeModelSpec.modality == .image ? selectedImageResolution : selectedVideoResolution

        var chatPayload: [[String: String]] = []
        var assistantRowIndex: Int? = nil
        if activeModelSpec.modality == .llmVLM {
            let userTurn = ChatTurnItem(
                role: "user",
                content: promptTrimmed,
                hasImage: (taskModeId == "vlm" && (firstFrameImage != nil || lastFrameImage != nil))
            )
            chatHistory.append(userTurn)
            chatPayload = chatHistory.map { ["role": $0.role, "content": $0.content] }
            let placeholderAssistant = ChatTurnItem(role: "assistant", content: "", thinking: "")
            chatHistory.append(placeholderAssistant)
            assistantRowIndex = chatHistory.count - 1
        }

        do {
            var req = URLRequest(url: submitURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.timeoutInterval = 30

            var payload: [String: Any] = [
                "model_id": selectedModelId,
                "task_mode": taskModeId,
                "visual_prompt": promptTrimmed,
                "negative_prompt": negativePrompt,
                "soundscape_prompt": soundscapePrompt,
                "music_prompt": musicPrompt,
                "width": resOpt.width,
                "height": resOpt.height,
                "num_frames": Int(numFrames),
                "num_inference_steps": Int(inferenceSteps),
                "fps": Int(fps),
                "seed": seed,
                "randomize_seed": randomizeSeed,
                "batch_count": activeModelSpec.modality == .llmVLM ? 1 : batchCount,
                "denoising_strength": denoisingStrength,
                "enable_thinking": enableThinking,
                "max_new_tokens": Int(maxNewTokens),
                "context_length": contextLengthTokens,
                "temperature": temperature,
                "top_p": topP,
                "top_k": 20,
                "min_p": 0.0,
                "presence_penalty": presencePenalty,
                "repeat_penalty": 1.0,
                "reasoning_effort": reasoningEffort
            ]
            if !chatPayload.isEmpty {
                payload["chat_messages"] = chatPayload
            }

            let needsImage = ["fl2va", "i2v", "i2i_edit", "vlm"].contains(taskModeId)
            if needsImage {
                if let firstImg = firstFrameImage, let b64 = encodeImageToBase64(firstImg) {
                    payload["first_frame_base64"] = b64
                }
                if let lastImg = lastFrameImage, let b64 = encodeImageToBase64(lastImg) {
                    payload["last_frame_base64"] = b64
                }
            }

            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, _) = try await URLSession.shared.data(for: req)
            guard activeGenerationToken == myToken else { return }
            let job = try JSONDecoder().decode(ColabJobResponse.self, from: data)

            if job.status == "failed" {
                stopLiveGenerationTimer()
                isGenerating = false
                progressValue = 0.0
                statusMessage = job.message
                if let idx = assistantRowIndex, idx < chatHistory.count {
                    chatHistory[idx].content = L(
                        "推理失败：\(job.message)",
                        "Inference failed: \(localizeServerText(job.message))"
                    )
                }
                return
            }

            await pollColabJob(baseURL: base, jobId: job.job_id, assistantRowIndex: assistantRowIndex, token: myToken)

        } catch {
            guard activeGenerationToken == myToken else { return }
            stopLiveGenerationTimer()
            isGenerating = false
            progressValue = 0.0
            statusMessage = L(
                "提交任务失败: \(error.localizedDescription)",
                "Failed to submit job: \(error.localizedDescription)"
            )
        }
    }

    private func pollColabJob(baseURL: String, jobId: String, assistantRowIndex: Int?, token: UUID) async {
        guard let pollURL = URL(string: "\(baseURL)/minimax_api/job/\(jobId)") else {
            if activeGenerationToken == token {
                stopLiveGenerationTimer()
                isGenerating = false
            }
            return
        }

        var downloadedFilenames = Set<String>()
        var consecutivePollErrors = 0
        var consecutiveNotFound = 0
        let pollIntervalNs: UInt64 = assistantRowIndex != nil ? 600_000_000 : 1_000_000_000

        while isGenerating && activeGenerationToken == token {
            try? await Task.sleep(nanoseconds: pollIntervalNs)
            guard isGenerating && activeGenerationToken == token else { break }
            do {
                var req = URLRequest(url: pollURL)
                req.timeoutInterval = 30
                let (data, resp) = try await URLSession.shared.data(for: req)
                guard isGenerating && activeGenerationToken == token else { break }
                let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
                if code == 404 {
                    consecutiveNotFound += 1
                    if consecutiveNotFound >= 5 {
                        resetStaleRemoteRuntimeState(
                            reason: L(
                                "云端推理进程已中断（可能因显存溢出或实例释放），请重新唤醒实例。",
                                "Cloud inference process interrupted (OOM or runtime released). Please wake & deploy again."
                            )
                        )
                        break
                    }
                    continue
                }
                consecutiveNotFound = 0
                guard code == 200 else {
                    consecutivePollErrors += 1
                    if consecutivePollErrors >= 12 {
                        stopLiveGenerationTimer()
                        isGenerating = false
                        statusMessage = L(
                            "云端任务响应异常 (HTTP \(code))，已自动解除等待。",
                            "Cloud job returned HTTP \(code); unlocked controls automatically."
                        )
                        break
                    }
                    continue
                }
                consecutivePollErrors = 0
                let job = try JSONDecoder().decode(ColabJobResponse.self, from: data)
                if let tl = job.telemetry {
                    applyLiveTelemetrySnapshot(tl)
                }
                // 在文件彻底生成并下载回本地预览前，进度条最高锁定在 98%，杜绝“显示 100% 但视频尚未出来”
                if job.status != "completed" {
                    progressValue = min(0.98, max(0.0, job.progress))
                }
                statusMessage = job.message
                if let remoteEl = job.elapsed, remoteEl >= 0 {
                    currentJobElapsed = max(currentJobElapsed, remoteEl)
                }
                if let s = job.seed { self.seed = s }
                if let lines = job.console_lines, !lines.isEmpty {
                    self.liveConsoleLines = lines
                }

                // Qwen3.8-27B 实时流式更新思考链与回复正文
                if let idx = assistantRowIndex, idx < chatHistory.count {
                    if let thinkTxt = job.thinking_output {
                        chatHistory[idx].thinking = thinkTxt
                    }
                    if let ansTxt = job.text_output {
                        chatHistory[idx].content = ansTxt
                    }
                }

                // 视频或图像批量边生边回传预览
                if let completedItems = job.completed_videos {
                    for item in completedItems where !downloadedFilenames.contains(item.filename) {
                        guard activeGenerationToken == token else { break }
                        if let downloadURL = URL(string: "\(baseURL)\(item.video_url)") {
                            downloadedFilenames.insert(item.filename)
                            if job.status == "completed" && (job.batch_count ?? 1) <= 1 {
                                progressValue = 0.99
                                statusMessage = L(
                                    "云端渲染已完成，正在高速回传结果文件至本地预览 (99%)...",
                                    "Cloud rendering complete. Transferring output to Mac for preview (99%)..."
                                )
                            }
                            await downloadMediaToLocal(
                                from: downloadURL,
                                filename: item.filename,
                                elapsedSeconds: item.elapsed ?? job.elapsed,
                                keepGeneratingProgress: job.status != "completed"
                            )
                        }
                    }
                }

                guard activeGenerationToken == token else { break }

                if job.status == "completed" {
                    let finalElapsed = job.elapsed ?? currentJobElapsed
                    if finalElapsed > 0 {
                        lastCompletedElapsed = finalElapsed
                        currentJobElapsed = finalElapsed
                    }
                    if let fname = job.filename,
                       !downloadedFilenames.contains(fname),
                       let mediaPath = job.video_url,
                       let downloadURL = URL(string: "\(baseURL)\(mediaPath)") {
                        downloadedFilenames.insert(fname)
                        progressValue = 0.99
                        statusMessage = L(
                            "云端渲染已完成，正在高速回传结果文件至本地预览 (99%)...",
                            "Cloud rendering complete. Transferring output to Mac for preview (99%)..."
                        )
                        await downloadMediaToLocal(
                            from: downloadURL,
                            filename: fname,
                            elapsedSeconds: finalElapsed
                        )
                    }
                    guard activeGenerationToken == token else { break }
                    if assistantRowIndex == nil, (job.batch_count ?? 1) > 1, finalElapsed > 0 {
                        let cnt = job.batch_count ?? 1
                        statusMessage = L(
                            "批量生成 \(cnt) 项全部完成 · 总耗时 \(formatDuration(finalElapsed))（均值 \(formatDuration(finalElapsed / Double(cnt)))/项）",
                            "Batch of \(cnt) completed · Total \(formatDuration(finalElapsed)) (avg \(formatDuration(finalElapsed / Double(cnt)))/item)"
                        )
                    }
                    stopLiveGenerationTimer()
                    isGenerating = false
                    progressValue = 1.0
                    await checkColabStatus(silent: true)
                    break
                } else if job.status == "failed" {
                    if let idx = assistantRowIndex, idx < chatHistory.count, chatHistory[idx].content.isEmpty {
                        chatHistory[idx].content = localizeServerText(job.message)
                    }
                    stopLiveGenerationTimer()
                    isGenerating = false
                    progressValue = 0.0
                    stripConsoleProgressBars()
                    break
                }
            } catch {
                guard activeGenerationToken == token else { break }
                consecutivePollErrors += 1
                if consecutivePollErrors >= 12 {
                    stopLiveGenerationTimer()
                    isGenerating = false
                    statusMessage = L(
                        "与云端任务失去连接，已自动解除锁定: \(error.localizedDescription)",
                        "Lost connection to cloud job; unlocked controls automatically: \(error.localizedDescription)"
                    )
                    await checkColabStatus(silent: true)
                    break
                }
                continue
            }
        }
    }

    private func downloadMediaToLocal(
        from remoteURL: URL,
        filename: String,
        elapsedSeconds: Double? = nil,
        keepGeneratingProgress: Bool = false
    ) async {
        do {
            let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
            let destURL = localSaveDir.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.moveItem(at: tempURL, to: destURL)
            if let el = elapsedSeconds, el > 0 {
                mediaElapsedMap[destURL.lastPathComponent] = el
            }
            refreshLocalMedia()
            selectMedia(destURL)
            if !keepGeneratingProgress {
                progressValue = 1.0
                let isMP4 = destURL.pathExtension.lowercased() == "mp4"
                let kindZh = isMP4 ? "视频" : "图像"
                let kindEn = isMP4 ? "Video" : "Image"
                if let el = elapsedSeconds, el > 0 {
                    statusMessage = L(
                        "\(kindZh)生成完成 · 耗时 \(formatDuration(el)) · 已保存：\(destURL.lastPathComponent)",
                        "\(kindEn) generated in \(formatDuration(el)) · Saved: \(destURL.lastPathComponent)"
                    )
                } else {
                    statusMessage = L(
                        "结果已保存至本地并自动预览：\(destURL.lastPathComponent)",
                        "Saved locally and opened in preview: \(destURL.lastPathComponent)"
                    )
                }
            }
        } catch {
            statusMessage = L(
                "云端生成已完成，但下载至本地失败: \(error.localizedDescription)",
                "Cloud generation finished, but local download failed: \(error.localizedDescription)"
            )
        }
    }

    func disconnectRemoteColab() async {
        statusMessage = L(
            "正在释放云端 Colab 实例并同步账户计费状态...",
            "Terminating cloud Colab instances & syncing billing status..."
        )
        let base = normalizedBaseURL
        if !base.isEmpty, let url = URL(string: "\(base)/minimax_api/disconnect") {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.timeoutInterval = 8
            _ = try? await URLSession.shared.data(for: req)
        }

        if cliLoggedIn {
            let out = await runBridgeCommand(["stop_all"])
            if let data = out.data(using: .utf8),
               let decoded = try? JSONDecoder().decode(BridgeAuthStatusResponse.self, from: data) {
                officialCUBalance = decoded.paid_balance ?? officialCUBalance
                officialBurnRate = decoded.burn_rate_hourly ?? 0.0
                activeVMCount = decoded.active_assignments ?? 0
                statusMessage = decoded.message ?? L(
                    "已彻底释放全部云端实例，计费速率归零。",
                    "All cloud Colab instances terminated. Billing rate is now 0 CU/h."
                )
            }
        } else {
            statusMessage = L(
                "已发送释放指令，Colab 实例已停止计费。",
                "Release command sent. Colab runtime billing stopped."
            )
        }

        stopLiveGenerationTimer()
        isConnected = false
        modelLoaded = false
        loadedModelId = nil
        loadedModelIds = []
        loadedModelsDetail = []
        loadedContextLengthTokens = 0
        ramTotalGB = 0.0
        ramUsedGB = 0.0
        ramFreeGB = 0.0
        diskTotalGB = 0.0
        diskUsedGB = 0.0
        diskFreeGB = 0.0
        shmTotalGB = 0.0
        shmUsedGB = 0.0
        shmFreeGB = 0.0
        driveTotalGB = 0.0
        driveUsedGB = 0.0
        driveFreeGB = 0.0
        vramHistoryPct = []
        ramHistoryPct = []
        diskHistoryPct = []
        lastTelemetrySampleDate = .distantPast
        remoteContextSynced = false
        remoteIdleSynced = false
        remoteApiKeySynced = false
        uptimeSeconds = 0
        cuBurnRatePerHour = 0.0
    }

    private func encodeImageToBase64(_ image: NSImage) -> String? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) else {
            return nil
        }
        return jpegData.base64EncodedString()
    }
}

// MARK: - 实时硬件资源折线图表组件 (VRAM / RAM / Disk)

private func buildSmoothTelemetryPaths(
    samples: [Double],
    size: CGSize,
    topInset: CGFloat = 5,
    bottomInset: CGFloat = 4
) -> (line: Path, area: Path, points: [CGPoint]) {
    var linePath = Path()
    var areaPath = Path()
    guard !samples.isEmpty, size.width > 2, size.height > (topInset + bottomInset + 2) else {
        return (linePath, areaPath, [])
    }

    let usableH = size.height - topInset - bottomInset
    let pts: [CGPoint]
    if samples.count == 1 {
        let y = topInset + usableH * CGFloat(1.0 - min(1.0, max(0.0, samples[0])))
        pts = [CGPoint(x: 0, y: y), CGPoint(x: size.width, y: y)]
    } else {
        let stepX = size.width / CGFloat(samples.count - 1)
        pts = samples.enumerated().map { idx, val in
            let clamped = min(1.0, max(0.0, val))
            let x = CGFloat(idx) * stepX
            let y = topInset + usableH * CGFloat(1.0 - clamped)
            return CGPoint(x: x, y: y)
        }
    }

    let minY = topInset
    let maxY = size.height - bottomInset

    linePath.move(to: pts[0])
    for i in 0..<(pts.count - 1) {
        let p0 = i > 0 ? pts[i - 1] : pts[i]
        let p1 = pts[i]
        let p2 = pts[i + 1]
        let p3 = (i + 2 < pts.count) ? pts[i + 2] : p2

        let dx = p2.x - p1.x
        // 若相邻区间完全平坦，直接使用直线段防止任何贝塞尔过冲
        if abs(p2.y - p1.y) < 0.25 {
            linePath.addLine(to: p2)
        } else {
            let cp1 = CGPoint(
                x: p1.x + dx / 3.0,
                y: min(maxY, max(minY, p1.y + (p2.y - p0.y) / 6.0))
            )
            let cp2 = CGPoint(
                x: p2.x - dx / 3.0,
                y: min(maxY, max(minY, p2.y - (p3.y - p1.y) / 6.0))
            )
            linePath.addCurve(to: p2, control1: cp1, control2: cp2)
        }
    }

    areaPath.addPath(linePath)
    if let last = pts.last, let first = pts.first {
        areaPath.addLine(to: CGPoint(x: last.x, y: size.height))
        areaPath.addLine(to: CGPoint(x: first.x, y: size.height))
        areaPath.closeSubpath()
    }

    return (linePath, areaPath, pts)
}

struct TelemetryGridBackground: View {
    let colorScheme: ColorScheme

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let gridColor = colorScheme == .dark
                ? Color.white.opacity(0.075)
                : Color.black.opacity(0.065)

            Path { p in
                for frac in [0.25, 0.50, 0.75] {
                    let y = h * CGFloat(frac)
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: w, y: y))
                }
                for frac in [0.25, 0.50, 0.75] {
                    let x = w * CGFloat(frac)
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: h))
                }
            }
            .stroke(gridColor, style: StrokeStyle(lineWidth: 0.65, dash: [2.5, 2.5]))
        }
    }
}

struct SingleMetricLineChartCard: View {
    let title: String
    let usedGB: Double
    let freeGB: Double
    let totalGB: Double
    let samples: [Double]
    let accentColor: Color
    let isWarning: Bool
    let isCritical: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var hoverLocationX: CGFloat? = nil

    private var effectiveColor: Color {
        if isCritical { return .red }
        if isWarning { return .orange }
        return accentColor
    }

    private func fmt1(_ val: Double) -> String {
        String(format: "%.1f", val)
    }

    var body: some View {
        let palette = StudioPalette(colorScheme: colorScheme)
        let currentPct = totalGB > 0 ? min(1.0, max(0.0, usedGB / totalGB)) : 0.0
        let plotSamples = samples.isEmpty ? Array(repeating: currentPct, count: 14) : samples

        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Circle()
                    .fill(effectiveColor)
                    .frame(width: 6.5, height: 6.5)
                    .shadow(color: effectiveColor.opacity(0.55), radius: 2.5)

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(String(format: "%.0f%%", currentPct * 100.0))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(effectiveColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(effectiveColor.opacity(colorScheme == .dark ? 0.18 : 0.12))
                    )

                Spacer(minLength: 4)

                Text(L(
                    "\(fmt1(usedGB))/\(fmt1(totalGB))G · 余\(fmt1(freeGB))G",
                    "\(fmt1(usedGB))/\(fmt1(totalGB))G · \(fmt1(freeGB))G free"
                ))
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(isCritical ? Color.red : (isWarning ? Color.orange : Color.secondary))
                    .lineLimit(1)
            }

            GeometryReader { geo in
                let built = buildSmoothTelemetryPaths(samples: plotSamples, size: geo.size)
                let hoverIdx: Int? = {
                    guard let hx = hoverLocationX, geo.size.width > 1, !built.points.isEmpty else { return nil }
                    let ratio = min(1.0, max(0.0, hx / geo.size.width))
                    return min(built.points.count - 1, max(0, Int(round(ratio * CGFloat(built.points.count - 1)))))
                }()

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 6.5)
                        .fill(
                            colorScheme == .dark
                                ? Color.black.opacity(0.26)
                                : Color(red: 0.962, green: 0.970, blue: 0.984)
                        )

                    TelemetryGridBackground(colorScheme: colorScheme)
                        .clipShape(RoundedRectangle(cornerRadius: 6.5))

                    built.area
                        .fill(
                            LinearGradient(
                                colors: [
                                    effectiveColor.opacity(colorScheme == .dark ? 0.34 : 0.24),
                                    effectiveColor.opacity(0.02)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6.5))

                    built.line
                        .stroke(
                            effectiveColor,
                            style: StrokeStyle(lineWidth: 1.75, lineCap: .round, lineJoin: .round)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6.5))

                    if let hi = hoverIdx, hi < built.points.count, hi < plotSamples.count {
                        let hp = built.points[hi]
                        let hPct = plotSamples[hi]
                        let hGB = hPct * totalGB

                        Path { p in
                            p.move(to: CGPoint(x: hp.x, y: 0))
                            p.addLine(to: CGPoint(x: hp.x, y: geo.size.height))
                        }
                        .stroke(effectiveColor.opacity(0.55), style: StrokeStyle(lineWidth: 1.0, dash: [2, 2]))

                        Circle()
                            .fill(effectiveColor)
                            .frame(width: 6, height: 6)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.2))
                            .position(hp)

                        Text("\(fmt1(hGB)) GB (\(String(format: "%.0f%%", hPct * 100)))")
                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(palette.workspaceCardFill.opacity(0.94))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(effectiveColor.opacity(0.45), lineWidth: 0.7)
                                    )
                            )
                            .position(
                                x: min(max(46, hp.x), geo.size.width - 46),
                                y: 11
                            )
                    } else if let lastPt = built.points.last {
                        Circle()
                            .fill(effectiveColor.opacity(0.28))
                            .frame(width: 10, height: 10)
                            .position(lastPt)

                        Circle()
                            .fill(effectiveColor)
                            .frame(width: 4.8, height: 4.8)
                            .position(lastPt)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 6.5)
                        .strokeBorder(palette.cardBorder, lineWidth: 0.8)
                )
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let loc):
                        hoverLocationX = loc.x
                    case .ended:
                        hoverLocationX = nil
                    }
                }
            }
            .frame(height: 38)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6.5)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(palette.inputFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(palette.cardBorder, lineWidth: 0.85)
                )
        )
    }
}

struct CombinedMultiMetricChartCard: View {
    let vramUsed: Double
    let vramTotal: Double
    let vramSamples: [Double]
    let ramUsed: Double
    let ramTotal: Double
    let ramSamples: [Double]
    let diskUsed: Double
    let diskTotal: Double
    let diskSamples: [Double]

    @Environment(\.colorScheme) private var colorScheme
    @State private var hoverX: CGFloat? = nil

    private let vramColor = Color(red: 0.33, green: 0.53, blue: 0.98)
    private let ramColor = Color(red: 0.10, green: 0.76, blue: 0.53)
    private let diskColor = Color(red: 0.05, green: 0.73, blue: 0.88)

    private func fmt1(_ val: Double) -> String {
        String(format: "%.1f", val)
    }

    var body: some View {
        let palette = StudioPalette(colorScheme: colorScheme)
        let vPct = vramTotal > 0 ? min(1.0, max(0.0, vramUsed / vramTotal)) : 0.0
        let rPct = ramTotal > 0 ? min(1.0, max(0.0, ramUsed / ramTotal)) : 0.0
        let dPct = diskTotal > 0 ? min(1.0, max(0.0, diskUsed / diskTotal)) : 0.0

        let vSeries = vramSamples.isEmpty ? Array(repeating: vPct, count: 14) : vramSamples
        let rSeries = ramSamples.isEmpty ? Array(repeating: rPct, count: 14) : ramSamples
        let dSeries = diskSamples.isEmpty ? Array(repeating: dPct, count: 14) : diskSamples

        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                let vBuilt = buildSmoothTelemetryPaths(samples: vSeries, size: geo.size, topInset: 6, bottomInset: 5)
                let rBuilt = buildSmoothTelemetryPaths(samples: rSeries, size: geo.size, topInset: 6, bottomInset: 5)
                let dBuilt = buildSmoothTelemetryPaths(samples: dSeries, size: geo.size, topInset: 6, bottomInset: 5)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(
                            colorScheme == .dark
                                ? Color.black.opacity(0.28)
                                : Color(red: 0.962, green: 0.970, blue: 0.984)
                        )

                    TelemetryGridBackground(colorScheme: colorScheme)
                        .clipShape(RoundedRectangle(cornerRadius: 7))

                    VStack {
                        Text("100%")
                        Spacer()
                        Text("50%")
                        Spacer()
                        Text("0%")
                    }
                    .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary.opacity(0.65))
                    .padding(.leading, 4)
                    .padding(.vertical, 3)

                    vBuilt.area
                        .fill(
                            LinearGradient(
                                colors: [vramColor.opacity(0.18), vramColor.opacity(0.01)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 7))

                    if diskTotal > 0 {
                        dBuilt.line
                            .stroke(diskColor, style: StrokeStyle(lineWidth: 1.55, lineCap: .round, lineJoin: .round))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    if ramTotal > 0 {
                        rBuilt.line
                            .stroke(ramColor, style: StrokeStyle(lineWidth: 1.65, lineCap: .round, lineJoin: .round))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    if vramTotal > 0 {
                        vBuilt.line
                            .stroke(vramColor, style: StrokeStyle(lineWidth: 1.85, lineCap: .round, lineJoin: .round))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }

                    if let hx = hoverX, geo.size.width > 1 {
                        let clampedX = min(geo.size.width, max(0, hx))
                        Path { p in
                            p.move(to: CGPoint(x: clampedX, y: 0))
                            p.addLine(to: CGPoint(x: clampedX, y: geo.size.height))
                        }
                        .stroke(Color.primary.opacity(0.32), style: StrokeStyle(lineWidth: 1.0, dash: [2.5, 2.5]))
                    } else {
                        if vramTotal > 0, let lp = vBuilt.points.last {
                            Circle().fill(vramColor).frame(width: 5, height: 5).position(lp)
                        }
                        if ramTotal > 0, let lp = rBuilt.points.last {
                            Circle().fill(ramColor).frame(width: 5, height: 5).position(lp)
                        }
                        if diskTotal > 0, let lp = dBuilt.points.last {
                            Circle().fill(diskColor).frame(width: 5, height: 5).position(lp)
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(palette.cardBorder, lineWidth: 0.8)
                )
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let loc):
                        hoverX = loc.x
                    case .ended:
                        hoverX = nil
                    }
                }
            }
            .frame(height: 88)

            VStack(spacing: 3.5) {
                if vramTotal > 0 {
                    legendRow(color: vramColor, label: L("显存 VRAM", "VRAM"), pct: vPct, used: vramUsed, total: vramTotal)
                }
                if ramTotal > 0 {
                    legendRow(color: ramColor, label: L("内存 RAM", "System RAM"), pct: rPct, used: ramUsed, total: ramTotal)
                }
                if diskTotal > 0 {
                    legendRow(color: diskColor, label: L("硬盘 Disk", "Disk"), pct: dPct, used: diskUsed, total: diskTotal)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(palette.inputFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(palette.cardBorder, lineWidth: 0.85)
                )
        )
    }

    @ViewBuilder
    private func legendRow(color: Color, label: String, pct: Double, used: Double, total: Double) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 8, height: 3.5)
            Text(label)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(fmt1(used)) / \(fmt1(total)) GB")
                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
            Text(String(format: "%3.0f%%", pct * 100))
                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .frame(width: 34, alignment: .trailing)
        }
    }
}

// MARK: - 图片拖拽与选择组件

struct FrameDropWell: View {
    let title: String
    let subtitle: String
    @Binding var image: NSImage?
    @Environment(\.colorScheme) private var colorScheme
    @State private var isTargeted: Bool = false

    var body: some View {
        let palette = StudioPalette(colorScheme: colorScheme)
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(palette.inputFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isTargeted ? Color.accentColor : palette.cardBorder,
                            style: StrokeStyle(lineWidth: isTargeted ? 2.0 : 1.2, dash: [6])
                        )
                )

            if let img = image {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
                    .padding(6)
                    .overlay(alignment: .topTrailing) {
                        Button {
                            image = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.white, .black.opacity(0.65))
                        }
                        .buttonStyle(.plain)
                        .padding(10)
                    }
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(L("选择本地图片", "Choose Image")) {
                        pickImage()
                    }
                    .controlSize(.small)
                    .padding(.top, 2)
                }
                .padding(12)
            }
        }
        .frame(height: 155)
        .onDrop(of: [.fileURL, .image], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    private func pickImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url, let loaded = NSImage(contentsOf: url) {
            image = loaded
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        if provider.canLoadObject(ofClass: URL.self) {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url, let loaded = NSImage(contentsOf: url) {
                    DispatchQueue.main.async { self.image = loaded }
                }
            }
            return true
        }
        return false
    }
}

// MARK: - 新手入门引导与分步使用指南弹窗

extension Notification.Name {
    static let openEasyColabGuide = Notification.Name("EasyColab.OpenOnboardingGuide")
}

private struct GuideStepMeta: Identifiable {
    let id: Int
    let badgeZh: String
    let badgeEn: String
    let titleZh: String
    let titleEn: String
    let subtitleZh: String
    let subtitleEn: String
    let icon: String

    var badge: String { L(badgeZh, badgeEn) }
    var title: String { L(titleZh, titleEn) }
    var subtitle: String { L(subtitleZh, subtitleEn) }
}

private let ONBOARDING_STEPS: [GuideStepMeta] = [
    GuideStepMeta(
        id: 0,
        badgeZh: "第 1 步",
        badgeEn: "Step 1",
        titleZh: "连接云端 96GB 显卡",
        titleEn: "Connect Cloud 96GB GPU",
        subtitleZh: "绑定账号 · 一键唤醒 G4 实例",
        subtitleEn: "Bind Google · 1-Click Wake G4 VM",
        icon: "bolt.horizontal.circle.fill"
    ),
    GuideStepMeta(
        id: 1,
        badgeZh: "第 2 步",
        badgeEn: "Step 2",
        titleZh: "下载与加载开源模型",
        titleEn: "Download & Load Open Models",
        subtitleZh: "云盘永久保存 · 大内存热备共驻",
        subtitleEn: "Drive Persistence · Co-Resident VRAM",
        icon: "square.stack.3d.up.fill"
    ),
    GuideStepMeta(
        id: 2,
        badgeZh: "第 3 步",
        badgeEn: "Step 3",
        titleZh: "四大模式快速上手",
        titleEn: "4 Creative Studio Modes",
        subtitleZh: "有声视频 · ComfyUI · 对话 · 生图",
        subtitleEn: "Video+Audio · ComfyUI · Chat · Image",
        icon: "sparkles.rectangle.stack.fill"
    ),
    GuideStepMeta(
        id: 3,
        badgeZh: "第 4 步",
        badgeEn: "Step 4",
        titleZh: "作品保存与省额度秘籍",
        titleEn: "Output Saving & CU Tips",
        subtitleZh: "自动回传本地 · 防忘关机自动释放",
        subtitleEn: "Auto Local Sync · Idle Auto-Release",
        icon: "checkmark.shield.fill"
    )
]

typealias ColabGuideSheetView = ColabGuideSheet

struct ColabGuideSheet: View {
    @ObservedObject var vm: StudioViewModel
    @ObservedObject private var i18n = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentStep: Int = 0

    private func revealServerNotebookInFinder() {
        let fm = FileManager.default
        if let repo = LocalRuntimePaths.repoRootIfPresent {
            let repoNb = repo.appendingPathComponent("EasyColab_Server.ipynb")
            if fm.fileExists(atPath: repoNb.path) {
                NSWorkspace.shared.activateFileViewerSelecting([repoNb])
                return
            }
        }
        let bundledPath = LocalRuntimePaths.resolveBundledOrRepoFile("EasyColab_Server.ipynb")
        if fm.fileExists(atPath: bundledPath),
           let downloadsDir = fm.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            let dest = downloadsDir.appendingPathComponent("EasyColab_Server.ipynb")
            try? fm.removeItem(at: dest)
            try? fm.copyItem(atPath: bundledPath, toPath: dest.path)
            if fm.fileExists(atPath: dest.path) {
                NSWorkspace.shared.activateFileViewerSelecting([dest])
                return
            }
        }
    }

    private func completeAndClose() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboardingGuide_v1")
        dismiss()
    }

    private func jumpToModel(_ modelId: String) {
        if let spec = OPEN_MODEL_CATALOG.first(where: { $0.id == modelId }) {
            vm.switchSelectedModel(spec)
        }
        completeAndClose()
    }

    var body: some View {
        let palette = StudioPalette(colorScheme: colorScheme)
        HStack(spacing: 0) {
            // 左侧步骤导航栏
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 9) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.10, green: 0.28, blue: 0.68),
                                        Color(red: 0.16, green: 0.48, blue: 0.92)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 30, height: 30)

                    VStack(alignment: .leading, spacing: 1.5) {
                        Text(L("EasyColab 指南", "EasyColab Guide"))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        Text(L("3 分钟零基础快速上手", "Get started in 3 minutes"))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 4)

                VStack(spacing: 7) {
                    ForEach(ONBOARDING_STEPS) { step in
                        let selected = currentStep == step.id
                        Button {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                currentStep = step.id
                            }
                        } label: {
                            HStack(alignment: .center, spacing: 10) {
                                Image(systemName: step.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                                    .frame(width: 22)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(step.badge) · \(step.title)")
                                        .font(.system(size: 12.5, weight: selected ? .bold : .semibold))
                                        .foregroundStyle(selected ? Color.primary : Color.primary.opacity(0.82))
                                    Text(step.subtitle)
                                        .font(.system(size: 10.5))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(selected ? Color.accentColor.opacity(colorScheme == .dark ? 0.20 : 0.12) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .strokeBorder(selected ? Color.accentColor.opacity(0.45) : Color.clear, lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                // 左下角实时连接体检卡片
                VStack(alignment: .leading, spacing: 7) {
                    Text(L("当前环境状态", "Environment Status"))
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 6) {
                        StatusDot(color: vm.cliLoggedIn ? .green : .orange)
                        Text(vm.cliLoggedIn
                             ? L("Google 账号：已绑定", "Google Account: Connected")
                             : L("Google 账号：待绑定", "Google Account: Unbound"))
                            .font(.system(size: 11, weight: .medium))
                    }

                    HStack(spacing: 6) {
                        StatusDot(color: vm.isConnected ? .green : .secondary.opacity(0.5))
                        Text(vm.isConnected
                             ? L("云端算力：\(vm.displayGpuName)", "Cloud GPU: \(vm.displayGpuName)")
                             : L("云端算力：尚未唤醒连接", "Cloud GPU: Not Connected"))
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                    }
                }
                .padding(11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(palette.sidebarCardFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(palette.cardBorder, lineWidth: 0.8)
                )
            }
            .padding(18)
            .frame(width: 232)
            .frame(maxHeight: .infinity)
            .background(palette.sidebarBackground)

            Rectangle()
                .fill(palette.splitDivider)
                .frame(width: 1)

            // 右侧主引导内容区
            VStack(alignment: .leading, spacing: 0) {
                // 顶部标题栏
                HStack(alignment: .top) {
                    let meta = ONBOARDING_STEPS[currentStep]
                    VStack(alignment: .leading, spacing: 5) {
                        Text("STEP 0\(currentStep + 1) / 04")
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(Color.accentColor.opacity(0.12)))

                        Text(meta.title)
                            .font(.system(size: 20, weight: .bold))
                        Text(meta.subtitle)
                            .font(.system(size: 12.5))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 10) {
                        Button {
                            vm.toggleLanguage()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "globe")
                                    .font(.system(size: 11, weight: .semibold))
                                Text(i18n.isEN ? "中文" : "EN")
                                    .font(.system(size: 11.5, weight: .semibold))
                            }
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                            .overlay(Capsule().strokeBorder(Color.accentColor.opacity(0.32), lineWidth: 0.8))
                        }
                        .buttonStyle(.plain)
                        .fixedSize()
                        .help(i18n.isEN ? "切换界面为简体中文" : "Switch UI to English")

                        Button {
                            completeAndClose()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.secondary.opacity(0.75))
                        }
                        .buttonStyle(.plain)
                        .help(L("关闭引导页", "Close Guide"))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 14)

                Divider()

                // 分步核心教程卡片区
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        switch currentStep {
                        case 0:
                            stepOneConnectView(palette: palette)
                        case 1:
                            stepTwoModelView(palette: palette)
                        case 2:
                            stepThreeWorkflowsView(palette: palette)
                        default:
                            stepFourSafetyView(palette: palette)
                        }
                    }
                    .padding(22)
                }

                Divider()

                // 底部操作栏
                HStack(spacing: 10) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                    Text(L(
                        "随时可点击左上角「新手引导」或顶栏「使用指南」再次打开本页",
                        "Reopen anytime via 'Guide' at top-left or 'User Guide' in the top bar"
                    ))
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer()

                    if currentStep > 0 {
                        Button(L("上一步", "Previous")) {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                currentStep -= 1
                            }
                        }
                        .controlSize(.regular)
                    }

                    if currentStep < ONBOARDING_STEPS.count - 1 {
                        Button(L("下一步", "Next")) {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .keyboardShortcut(.defaultAction)
                    } else {
                        Button(L("开始创作", "Start Creating")) {
                            completeAndClose()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .keyboardShortcut(.defaultAction)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 13)
                .background(palette.workspaceCardFill)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.workspaceCanvas)
        }
        .id(i18n.lang)
        .frame(width: 840, height: 560)
        .onAppear {
            currentStep = max(0, min(ONBOARDING_STEPS.count - 1, vm.guideInitialStep))
            UserDefaults.standard.set(true, forKey: "hasSeenOnboardingGuide_v1")
        }
    }

    // MARK: - Step 1: 连接云端算力

    @ViewBuilder
    private func stepOneConnectView(palette: StudioPalette) -> some View {
        guideInfoCard(
            number: "1",
            title: L("绑定 Google 账号（仅首次需要一次）", "Bind Your Google Account (One-Time Setup)"),
            detail: L(
                "在主界面左侧「Colab 算力实例」卡片点击「绑定」，在弹出的浏览器页面登录开通了 Colab Pro / AI Ultra 的 Google 账号并粘贴授权码。绑定后会自动同步真实剩余 CU 计算单元与 Google Drive 云盘。",
                "In the left 'Colab Compute' card, click 'Bind', sign in with a Google account subscribed to Colab Pro / Pro+ / AI Ultra in your browser, and paste the authorization code. Your real CU balance and Google Drive will sync automatically."
            ),
            palette: palette
        ) {
            if !vm.cliLoggedIn {
                Button {
                    completeAndClose()
                    Task { await vm.startGoogleOAuthLogin() }
                } label: {
                    Label(L("现在去绑定 Google 账号", "Bind Google Account Now"), systemImage: "person.crop.circle.badge.checkmark")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Label(L("你的 Google 账号已完成绑定", "Your Google account is connected"), systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }

        guideInfoCard(
            number: "2",
            title: L("选择 G4 机型并点击「唤醒实例并部署」（免开网页）", "Select G4 & Click 'Wake & Deploy' (Browserless)"),
            detail: L(
                "默认已为你选中性价比最高的 G4 机型（NVIDIA RTX PRO 6000 · 96GB 超大显存 + 176GB 系统内存）。点击蓝色「唤醒实例并部署」按钮后，客户端会自动在云端拉起实例、挂载你的 Google Drive 云盘并完成自动连接，全程约 1～2 分钟。",
                "G4 (NVIDIA RTX PRO 6000 · 96GB VRAM + 176GB System RAM) is pre-selected for maximum price-performance. Click the blue 'Wake & Deploy' button to provision a cloud runtime, mount Google Drive, and connect automatically in ~1–2 minutes."
            ),
            palette: palette
        ) {
            if vm.cliLoggedIn && !vm.isConnected && !vm.isWakingColab {
                Button {
                    completeAndClose()
                    Task { await vm.wakeColabHeadless() }
                } label: {
                    Label(L("立即一键唤醒 G4 并部署", "Wake G4 & Deploy Now"), systemImage: "bolt.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }

        guideInfoCard(
            number: "3",
            title: L("备选方案：通过 Google Colab 网页端手动运行笔记本", "Alternative: Run the Notebook Manually in Google Colab Web"),
            detail: L(
                "若你希望在浏览器里查看原生 Notebook，也可以把同步生成的 EasyColab_Server.ipynb 上传至 Colab 网页运行，再把生成的 https://xxxx.gradio.live 地址粘贴到左侧服务地址栏点击「连接」。",
                "Prefer running a notebook in your browser? Upload EasyColab_Server.ipynb to Google Colab, run the cell, then paste the generated https://xxxx.gradio.live URL into the Server URL field on the left and click 'Connect'."
            ),
            palette: palette
        ) {
            HStack(spacing: 10) {
                Button {
                    revealServerNotebookInFinder()
                } label: {
                    Label(L("导出 / 定位 .ipynb 笔记本", "Reveal .ipynb Notebook"), systemImage: "folder")
                }
                .controlSize(.small)

                Button {
                    if let url = URL(string: "https://colab.research.google.com/") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label(L("打开 Google Colab 官网", "Open Google Colab Web"), systemImage: "safari")
                }
                .controlSize(.small)
            }
        }
    }

    // MARK: - Step 2: 下载与加载模型

    @ViewBuilder
    private func stepTwoModelView(palette: StudioPalette) -> some View {
        guideInfoCard(
            number: "1",
            title: L("先点「下载权重」：一次存入 Google Drive，永久免重下", "Step 1 — 'Download Weights': Save Once to Google Drive Forever"),
            detail: L(
                "在左侧「开源模型中心」选中你想用的模型。第一次使用时点击「下载权重」，服务端会以 8 线程极速将模型直接下载进你的 Google Drive 云盘。以后每次重新唤醒新机器，都会秒级识别云盘已有权重，无需重复下载。",
                "Pick a model in 'Open Model Center' on the left. Click 'Download Weights' once — the server downloads shards at 8-thread speed directly into your Google Drive. Future runtimes detect existing Drive weights instantly without re-downloading."
            ),
            palette: palette
        ) { EmptyView() }

        guideInfoCard(
            number: "2",
            title: L("再点「加载到显存」：96GB 显存 + 176GB 内存热备加速", "Step 2 — 'Load to VRAM': 96GB VRAM + 176GB RAM Hot-Standby"),
            detail: L(
                "权重就绪后点击「加载到显存」即可开始生成。在 G4 机型上：\n• MiniMax-H3 原生 BF16 会自动激活「双主干内存热备」，同提示词换种子 0ms 瞬回，换新提示词解析仅需约 10 秒。\n• 支持多模型同时常驻显存（例如同时驻留 Qwen3.8-GGUF 对话与生图/视频模型），也可随时在卡片上点「卸载」单独释放。",
                "Once weights are ready, click 'Load to VRAM':\n• On G4, MiniMax-H3 Native BF16 activates dual-backbone RAM hot-standby — 0ms cache hit when changing seeds and ~10s encoding on new prompts.\n• Multiple models can co-reside in VRAM simultaneously (e.g. Qwen3.8-GGUF chat alongside image/video models) and be unloaded individually anytime."
            ),
            palette: palette
        ) { EmptyView() }

        guideInfoCard(
            number: "3",
            title: L("右侧实时日志与折线图监控", "Live Telemetry Charts & Real-Time Run Logs"),
            detail: L(
                "左下角算力卡片提供显存、系统内存与磁盘折线走势图（点切换按钮可合并/展开三线对比）；右侧独立面板实时滚动下载速率、采样步进度与预计剩余时间。",
                "The left compute card plots live VRAM, System RAM, and Disk curves (toggle between Split and Combined views), while the collapsible right log panel streams live download speeds, sampling steps, and ETA."
            ),
            palette: palette
        ) { EmptyView() }
    }

    // MARK: - Step 3: 四大创作模式快速上手

    @ViewBuilder
    private func stepThreeWorkflowsView(palette: StudioPalette) -> some View {
        guideInfoCard(
            number: "A",
            title: L("MiniMax-H3 · 4～15 秒电影级原生有声视频", "MiniMax-H3 · 4–15s Cinematic Video with Native Stereo Audio"),
            detail: L(
                "支持「文生有声视频」「首帧图生视频」「首尾帧生视频」三种模式。可分别填写画面描述、环境音效与背景配乐（也可点右上角「示例模板」一键填入），下方提供 4s / 5s / 8s / 10s / 12s / 15s 快捷时长按钮，直出带 32kHz 立体声的 MP4 成片。",
                "Supports Text-to-Video+Audio, Image-to-Video, and First/Last Frame modes. Describe visual scenes, soundscapes/dialogue, and music (or insert a preset from 'Templates'), pick 4s–15s duration chips, and render MP4s with 32kHz stereo audio."
            ),
            palette: palette
        ) {
            Button {
                jumpToModel("minimax_h3")
            } label: {
                Label(L("切换至 MiniMax-H3 视频工作台", "Switch to MiniMax-H3 Video Studio"), systemImage: "film.stack")
            }
            .controlSize(.small)
        }

        guideInfoCard(
            number: "B",
            title: L("ComfyUI 节点工作台 · 预置 4 套零基础中文傻瓜工作流", "ComfyUI Node Studio · 4 Turnkey Preset Video Workflow Packs"),
            detail: L(
                "不会连节点也能直接用：切到 ComfyUI -> 点击「一键部署并启动」-> 在下方「预置图生视频 / 首尾帧运镜工作流包」任选万相 Wan2.2 / MiniMax-H3 / LTX-2.3 / 混元 1.5 点「一键配齐」-> 点击打开免费公网画布 -> 左上角「工作流」菜单打开中文模板 -> 上传首尾图片点「运行」即可！所有插件、模型与工作流均自动持久化到云盘。",
                "No node wiring required: switch to ComfyUI -> click 'Start ComfyUI' -> pick Wan2.2 / MiniMax-H3 / LTX-2.3 / Hunyuan 1.5 under Preset Workflow Packs and click '1-Click Install' -> open the fullscreen canvas -> select a template from Workflows -> upload 1–2 images and hit Run! All custom nodes, models, and workflows persist to Google Drive."
            ),
            palette: palette
        ) {
            Button {
                jumpToModel("comfyui_studio")
            } label: {
                Label(L("切换至 ComfyUI 节点工作台", "Switch to ComfyUI Node Studio"), systemImage: "point.3.connected.trianglepath.dotted")
            }
            .controlSize(.small)
        }

        guideInfoCard(
            number: "C",
            title: L("Qwen3.8-27B (GGUF 100 tok/s) · 视觉对话与 Claude/OpenAI 网关", "Qwen3.8-27B (GGUF 100 tok/s) · Vision Chat & Claude/OpenAI API Gateway"),
            detail: L(
                "推荐日常选择 GGUF 量化版（仅占约 21GB 显存，生成高达 100 tok/s，支持最高 256K 上下文与拖入图片反推提示词）。切换到「API 协议网关」标签还可一键复制兼容 OpenAI 与 Anthropic 的公网接口，直接接入 Claude Code 或 Cursor。",
                "Recommended for daily use (~21GB VRAM, up to 100 tok/s, up to 256K context, and drag-and-drop image analysis). Switch to the 'API Gateway' mode card to copy OpenAI `/v1` and Anthropic `/v1/messages` endpoints for Claude Code or Cursor."
            ),
            palette: palette
        ) {
            Button {
                jumpToModel("qwen38_27b_gguf")
            } label: {
                Label(L("切换至 Qwen3.8-GGUF 极速对话与网关", "Switch to Qwen3.8-GGUF Chat & Gateway"), systemImage: "bubble.left.and.bubble.right")
            }
            .controlSize(.small)
        }

        guideInfoCard(
            number: "D",
            title: L("Qwen-Image-2.1 / Z-Image-Turbo · 2K 海报生图与自然语言修图", "Qwen-Image-2.1 / Z-Image-Turbo · 2K Poster Generation & Image Editing"),
            detail: L(
                "支持精准中英文海报排版直出，以及上传 1～2 张参考图用一句话指令改服装、换背景或融合多图主体；Z-Image-Turbo 更支持 8 步秒级出图。",
                "Render crisp bilingual typography posters, or upload 1–2 reference images for natural-language outfit swaps, background replacement, and multi-subject fusion; Z-Image-Turbo delivers sub-second 8-step generation."
            ),
            palette: palette
        ) {
            Button {
                jumpToModel("qwen_image_21")
            } label: {
                Label(L("切换至 Qwen-Image-2.1 图像工作台", "Switch to Qwen-Image-2.1 Image Studio"), systemImage: "paintbrush.pointed")
            }
            .controlSize(.small)
        }
    }

    // MARK: - Step 4: 作品保存与省额度秘籍

    @ViewBuilder
    private func stepFourSafetyView(palette: StudioPalette) -> some View {
        guideInfoCard(
            number: "1",
            title: L("生成作品自动回传 Mac 本地 + 云盘双保险", "Auto-Save Outputs to Local Mac + Google Drive Backup"),
            detail: L(
                "所有生成的 MP4 有声视频和 PNG 高清大图都会自动下载回你的 Mac 本地影片目录（Movies/EasyColab），中间预览区可直接播放或切换历史缩略图；ComfyUI 跑出的视频也能在「极速下权重与回传成片」页一键拉回本地。",
                "Every generated MP4 video and PNG image downloads automatically to your Mac (`~/Movies/EasyColab`) for instant playback and history browsing; ComfyUI renders can also be pulled to your Mac in one click."
            ),
            palette: palette
        ) {
            Button {
                NSWorkspace.shared.open(vm.localSaveDir)
            } label: {
                Label(L("打开 Mac 本地作品输出目录", "Open Local Output Folder"), systemImage: "folder")
            }
            .controlSize(.small)
        }

        guideInfoCard(
            number: "2",
            title: L("开启自动休眠 + 用完点「释放全部实例」立省 CU 额度", "Idle Auto-Sleep + 'Release All Instances' Saves Compute Units"),
            detail: L(
                "Colab 按 GPU 在线时长消耗计算单元（CU）：\n• 左侧「算力额度与自动休眠」默认开启 30 分钟闲置看门狗，长时间离开会自动销毁虚拟机防止忘关机。\n• 当天创作结束时，建议直接点击左侧红色的「释放全部实例」按钮，云端 GPU 立即销毁、计费瞬间归零！",
                "Colab bills Compute Units (CU) while a GPU VM is online:\n• 'Compute Quota & Auto-Sleep' enables a 30-minute idle watchdog by default to auto-terminate forgotten runtimes.\n• When done for the day, click the red 'Release All Instances' button on the left to destroy cloud VMs and stop CU burn immediately!"
            ),
            palette: palette
        ) { EmptyView() }

        guideInfoCard(
            number: "3",
            title: L("免费 Cloudflare 加密公网隧道说明", "Free Encrypted Cloudflare Quick Tunnel"),
            detail: L(
                "ComfyUI 使用的 *.trycloudflare.com 随机公网链接由 Cloudflare 官方免费 Quick Tunnel 提供，0 元免注册、全程 HTTPS 加密，且每次释放 Colab 实例后自动销毁失效，安全省心。",
                "ComfyUI's random `*.trycloudflare.com` URL is powered by Cloudflare's official free Quick Tunnel — zero cost, no signup, end-to-end HTTPS encryption, and automatically invalidated whenever the Colab VM is released."
            ),
            palette: palette
        ) { EmptyView() }
    }

    @ViewBuilder
    private func guideInfoCard<ActionContent: View>(
        number: String,
        title: String,
        detail: String,
        palette: StudioPalette,
        @ViewBuilder action: () -> ActionContent
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.accentColor))
                .foregroundStyle(.white)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2.5)

                action()
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(palette.workspaceCardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(palette.cardBorder, lineWidth: 0.8)
        )
    }
}

// MARK: - 通用 UI 容器组件

struct SidebarCard<Content: View>: View {
    let title: String
    let icon: String
    var badge: String? = nil
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder var content: () -> Content

    var body: some View {
        let palette = StudioPalette(colorScheme: colorScheme)
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text(title)
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.primary.opacity(0.06)))
                }
            }

            content()
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(palette.sidebarCardFill)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.22 : 0.04), radius: 3, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(palette.cardBorder, lineWidth: 0.8)
        )
    }
}

struct WorkspaceCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var trailing: AnyView? = nil
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder var content: () -> Content

    var body: some View {
        let palette = StudioPalette(colorScheme: colorScheme)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    if let subtitle {
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let trailing { trailing }
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 11)
                .fill(palette.workspaceCardFill)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.035), radius: 4, x: 0, y: 1.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .strokeBorder(palette.cardBorder, lineWidth: 0.8)
        )
    }
}

struct StatusDot: View {
    let color: Color
    var body: some View {
        Circle().fill(color).frame(width: 8, height: 8)
    }
}

private func fmt(_ v: Double, _ digits: Int = 2) -> String {
    String(format: "%.\(digits)f", v)
}

// MARK: - 主界面视图（左：控制栏 | 中：创作与网关工作台 | 右：独立全高运行日志）

struct MainStudioView: View {
    @StateObject private var vm = StudioViewModel()
    @ObservedObject private var i18n = LanguageManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showFileList: Bool = false
    @State private var showNegativePrompt: Bool = false
    @State private var openaiSnippetTab: Int = 0
    @State private var anthropicSnippetTab: Int = 0
    @State private var showRightLogPanel: Bool = true
    @State private var showDriveConnection = false
    @StateObject private var driveController = DriveConnectionController()
    @State private var showProcessMonitor = false
    @State private var monitorGPU = false
    @State private var expandStatusMessage = false

    private var isTaskStreaming: Bool {
        vm.isWakingColab
            || vm.isDownloadingWeights
            || vm.isLoadingModel
            || vm.isUnloadingModel
            || vm.isGenerating
            || vm.comfyStarting
            || vm.comfyDownloadingWeight
            || vm.comfySyncingDrive
            || vm.comfyQueueRunning > 0
    }

    var body: some View {
        let palette = StudioPalette(colorScheme: colorScheme)

        HStack(spacing: 0) {
            // 1. 左侧独立底色控制面板（从窗口最顶部 y=0 贯通到底部）
            VStack(spacing: 0) {
                sidebarTopHeader(palette: palette)
                Rectangle()
                    .fill(palette.splitDivider)
                    .frame(height: 1)
                sidebarPanel(palette: palette)
            }
            .frame(width: 356)
            .background(palette.sidebarBackground)

            // 左-中贯通全高 1pt 锐利分界线
            Rectangle()
                .fill(palette.splitDivider)
                .frame(width: 1)

            // 2. 中间主工作区画布（从窗口最顶部 y=0 贯通到底部）
            VStack(spacing: 0) {
                workspaceTopHeader(palette: palette)
                Rectangle()
                    .fill(palette.splitDivider)
                    .frame(height: 1)
                workspacePanel(palette: palette)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 540, maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.workspaceCanvas)

            // 3. 右侧独立全高运行日志面板（从窗口最顶部 y=0 贯通到底部）
            if showRightLogPanel {
                Rectangle()
                    .fill(palette.splitDivider)
                    .frame(width: 1)

                VStack(spacing: 0) {
                    logPanelTopHeader(palette: palette)
                    Rectangle()
                        .fill(palette.splitDivider)
                        .frame(height: 1)
                    rightLogPanel(palette: palette)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 352)
                .background(palette.logPanelBackground)
            }
        }
        .id(i18n.lang)
        .ignoresSafeArea(.container, edges: .top)
        .background(TitlebarConfigurator(headerHeight: 40))
        .sheet(isPresented: $vm.showColabGuideSheet) {
            ColabGuideSheet(vm: vm)
        }
        .sheet(isPresented: $showDriveConnection) {
            DriveConnectionView(controller: driveController, chinese: !i18n.isEN) { arguments in
                Task { await vm.runDriveCommand(driveController, arguments: arguments) }
            }
        }
        .sheet(isPresented: $showProcessMonitor) {
            ProcessMonitorView(baseURL: vm.normalizedBaseURL, apiKey: vm.apiAccessKey, chinese: !i18n.isEN, gpuMode: monitorGPU)
        }
        .onAppear {
            if !UserDefaults.standard.bool(forKey: "hasSeenOnboardingGuide_v1") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    vm.openOnboardingGuide(step: 0)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openEasyColabGuide)) { _ in
            vm.openOnboardingGuide(step: 0)
        }
        .alert(L("释放所有 Colab 实例？", "Release All Colab Instances?"), isPresented: $vm.showDisconnectConfirm) {
            Button(L("取消", "Cancel"), role: .cancel) {}
            Button(L("释放", "Release"), role: .destructive) {
                Task { await vm.disconnectRemoteColab() }
            }
        } message: {
            Text(L(
                "账号下所有运行中的 Colab GPU 实例将被销毁，计费立即归零。",
                "All active Colab GPU runtimes under your account will be terminated and CU billing will stop immediately."
            ))
        }
    }

    // MARK: - 一体化无缝顶栏（左中右独立底色 + 1pt 贯通分界线 + 原生拖拽）

    private func sidebarTopHeader(palette: StudioPalette) -> some View {
        HStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(red: 0.88, green: 0.95, blue: 0.98))
                Image(systemName: "cloud.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                Canvas { context, size in
                    let points = [CGPoint(x: 5.5, y: 11.7), CGPoint(x: 10, y: 8.5), CGPoint(x: 14.5, y: 11.7)]
                    var line = Path()
                    line.move(to: points[0])
                    line.addLine(to: points[1])
                    line.addLine(to: points[2])
                    context.stroke(line, with: .color(Color(red: 0.98, green: 0.43, blue: 0.19)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    for point in points {
                        context.fill(Path(ellipseIn: CGRect(x: point.x - 1.15, y: point.y - 1.15, width: 2.3, height: 2.3)), with: .color(Color(red: 1, green: 0.58, blue: 0.27)))
                    }
                }
            }
            .frame(width: 20, height: 20)

            Text("EasyColab")
                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .fixedSize()

            Spacer(minLength: 4)

            HStack(spacing: 5) {
                Button {
                    vm.toggleLanguage()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "globe")
                            .font(.system(size: 10, weight: .semibold))
                        Text(i18n.isEN ? "中文" : "EN")
                            .font(.system(size: 10.5, weight: .semibold))
                    }
                    .foregroundStyle(.primary.opacity(0.85))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(
                        Capsule()
                            .fill(Color.primary.opacity(0.06))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(palette.cardBorder, lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .fixedSize()
                .help(i18n.isEN ? "切换界面为简体中文" : "Switch UI to English")

                Button {
                    vm.openOnboardingGuide(step: 0)
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .semibold))
                        Text(L("新手引导", "Guide"))
                            .font(.system(size: 10.5, weight: .semibold))
                    }
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 7.5)
                    .padding(.vertical, 3.5)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.12))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.accentColor.opacity(0.32), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .fixedSize()
                .help(L("查看 EasyColab 新手入门引导与分步使用教程", "Open EasyColab quick start guide & walkthrough"))
            }
        }
        .padding(.leading, 76)
        .padding(.trailing, 12)
        .frame(height: 40)
        .background(WindowDragHandle())
    }

    private func workspaceTopHeader(palette: StudioPalette) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                StatusDot(color: vm.isConnected ? .green : .secondary.opacity(0.45))
                let ramTag = vm.ramTotalGB > 0
                    ? L(" · 内存 \(fmt(vm.ramUsedGB, 1))/\(fmt(vm.ramTotalGB, 0))G", " · RAM \(fmt(vm.ramUsedGB, 1))/\(fmt(vm.ramTotalGB, 0))G")
                    : ""
                let diskTag = vm.diskTotalGB > 0
                    ? L(" · 磁盘可用 \(fmt(vm.diskFreeGB, 1))/\(fmt(vm.diskTotalGB, 0))G", " · Disk Free \(fmt(vm.diskFreeGB, 1))/\(fmt(vm.diskTotalGB, 0))G")
                    : ""
                Text(vm.isConnected
                     ? L("\(vm.displayGpuName) · 显存 \(fmt(vm.vramUsedGB, 1))/\(fmt(vm.vramTotalGB, 0))G\(ramTag)\(diskTag)",
                         "\(vm.displayGpuName) · VRAM \(fmt(vm.vramUsedGB, 1))/\(fmt(vm.vramTotalGB, 0))G\(ramTag)\(diskTag)")
                     : L("开源多模型云端工作台", "Open Multi-Model Cloud Studio"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Menu {
                let matching = PRESET_TEMPLATES.filter {
                    $0.category == vm.activeModelSpec.modality
                        || (vm.activeModelSpec.modality == .video && $0.category == .videoAudio)
                }
                ForEach(matching.isEmpty ? PRESET_TEMPLATES : matching) { tpl in
                    Button(tpl.name) {
                        vm.visualPrompt = tpl.visual
                        if !tpl.soundscape.isEmpty { vm.soundscapePrompt = tpl.soundscape }
                        if !tpl.music.isEmpty { vm.musicPrompt = tpl.music }
                    }
                }
            } label: {
                Label(L("示例模板", "Templates"), systemImage: "text.badge.plus")
                    .font(.system(size: 12, weight: .medium))
            }
            .controlSize(.small)
            .help(L("填入当前模型精选提示词模板", "Insert curated prompt templates for the active model"))

            Button {
                NSWorkspace.shared.open(vm.localSaveDir)
            } label: {
                Label(L("本地输出目录", "Output Folder"), systemImage: "folder")
                    .font(.system(size: 12, weight: .medium))
            }
            .controlSize(.small)
            .help(L("打开本地保存的视频与图像文件夹", "Open local folder for saved videos & images"))

            Button {
                vm.openOnboardingGuide(step: 0)
            } label: {
                Label(L("使用指南", "User Guide"), systemImage: "book.pages")
                    .font(.system(size: 12, weight: .medium))
            }
            .controlSize(.small)
            .help(L("重新打开新手引导页与完整使用指南", "Reopen the interactive onboarding & user guide"))

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    showRightLogPanel.toggle()
                }
            } label: {
                Image(systemName: "sidebar.right")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(showRightLogPanel ? Color.accentColor : Color.secondary)
            }
            .controlSize(.small)
            .help(showRightLogPanel
                  ? L("收起右侧运行日志面板", "Hide right run log panel")
                  : L("展开右侧运行日志面板", "Show right run log panel"))
        }
        .padding(.horizontal, 18)
        .frame(height: 40)
        .background(
            palette.workspaceCardFill
                .overlay(WindowDragHandle())
        )
    }

    private func logPanelTopHeader(palette: StudioPalette) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "terminal")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.accentColor)

            Text(L("运行日志", "Run Logs"))
                .font(.system(size: 12.5, weight: .bold))
                .foregroundStyle(.primary)

            HStack(spacing: 4) {
                Circle()
                    .fill(isTaskStreaming ? Color.green : Color.secondary.opacity(0.45))
                    .frame(width: 5.5, height: 5.5)
                Text(isTaskStreaming
                     ? L("实时传输", "Live")
                     : L("\(vm.liveConsoleLines.count) 行", "\(vm.liveConsoleLines.count) lines"))
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(isTaskStreaming ? Color.green : .secondary)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.primary.opacity(0.06)))

            Spacer()

            Button {
                copyToPasteboard(
                    vm.maskedConsoleDisplay(vm.liveConsoleLines.map(localizeConsoleLine).joined(separator: "\n")),
                    tip: L("已复制全部运行日志到剪贴板", "Copied all run logs to clipboard")
                )
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11.5, weight: .medium))
            }
            .buttonStyle(.borderless)
            .help(L("复制全部日志", "Copy all logs"))

            Button {
                vm.liveConsoleLines = [L(StudioViewModel.clearedConsoleLineZh, StudioViewModel.clearedConsoleLineEn)]
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11.5, weight: .medium))
            }
            .buttonStyle(.borderless)
            .help(L("清空当前日志", "Clear console logs"))
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(
            palette.logHeaderBackground
                .overlay(WindowDragHandle())
        )
    }

    // MARK: - 左侧控制栏（独立冷灰蓝底色 + 悬浮白卡片）

    private func sidebarPanel(palette: StudioPalette) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                SidebarCard(
                    title: L("Colab 算力实例", "Colab Compute Instance"),
                    icon: "cpu",
                    badge: vm.isConnected ? L("在线", "Online") : L("离线", "Offline")
                ) {
                    colabConnectionRows
                }

                SidebarCard(
                    title: L("算力额度与自动休眠", "Compute Quota & Auto-Sleep"),
                    icon: "gauge.with.dots.needle.33percent"
                ) {
                    usageRows
                }

                SidebarCard(
                    title: L("开源模型中心", "Open Model Center"),
                    icon: "square.stack.3d.up",
                    badge: vm.loadedModelIds.isEmpty
                        ? "HF Top \(OPEN_MODEL_CATALOG.count)"
                        : L("共驻 \(vm.loadedModelIds.count) 模型", "\(vm.loadedModelIds.count) in VRAM")
                ) {
                    openModelHubRows(palette: palette)
                }

                SidebarCard(
                    title: vm.activeModelSpec.modality == .comfyUI
                        ? L("ComfyUI 云盘持久化与控制", "ComfyUI Persistence & Controls")
                        : (vm.activeModelSpec.modality == .llmVLM
                           ? L("推理与对话参数", "Reasoning & Chat Params")
                           : L("规格与采样参数", "Specs & Sampling Params")),
                    icon: vm.activeModelSpec.modality == .comfyUI ? "externaldrive.badge.icloud" : "slider.horizontal.3"
                ) {
                    adaptiveParamRows
                }
            }
            .padding(14)
        }
        .compatScrollIndicatorMargins(.vertical, 6)
    }

    @ViewBuilder
    private var colabConnectionRows: some View {
        HStack(spacing: 6) {
            Text(L("Google 账号", "Google Account"))
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            Text(vm.displayAccountLabel)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(vm.cliLoggedIn ? Color.green : Color.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(vm.accountEmail.isEmpty ? L("当前 Google 账号状态", "Google account connection status") : vm.displayAccountLabel)

            if vm.cliLoggedIn {
                Button(L("刷新", "Refresh")) { Task { await vm.refreshOfficialColabAccountUsage() } }
                    .controlSize(.small)

                Menu {
                    Button {
                        Task { await vm.startGoogleOAuthLogin(switchingAccount: true) }
                    } label: {
                        Label(L("切换 Google 账号...", "Switch Google Account..."), systemImage: "arrow.triangle.2.circlepath")
                    }
                    Divider()
                    Button(role: .destructive) {
                        Task { await vm.logoutGoogleAccount() }
                    } label: {
                        Label(L("退出当前账号", "Sign Out"), systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Text(L("换号", "Account"))
                }
                .controlSize(.small)
                .fixedSize()
                .help(L("切换其他 Google 账号或退出当前绑定", "Switch to another Google account or sign out"))
            } else {
                Button(L("绑定", "Bind")) { Task { await vm.startGoogleOAuthLogin() } }
                    .controlSize(.small)
            }
        }

        HStack {
            Button(L("连接 Google Drive", "Connect Google Drive")) { showDriveConnection = true }
                .controlSize(.small)
                .help(L("浏览器授权 Drive，无需手工配置 rclone", "Authorize Drive in your browser without manual rclone setup"))
            if driveController.authorized { Image(systemName: "checkmark.shield").foregroundStyle(.green) }
        }

        if vm.showOAuthCodeInput {
            HStack(spacing: 6) {
                TextField(
                    L("授权码", "Auth Code"),
                    text: $vm.oauthCodeText,
                    prompt: Text(L("粘贴浏览器显示的授权码", "Paste auth code from browser"))
                )
                    .textFieldStyle(.roundedBorder)
                Button(L("确认", "Confirm")) { Task { await vm.submitGoogleOAuthCode() } }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                Button(L("取消", "Cancel")) {
                    vm.showOAuthCodeInput = false
                    vm.oauthCodeText = ""
                }
                .controlSize(.small)
            }
        }

        if vm.cliLoggedIn {
            HStack(spacing: 8) {
                Picker(L("机型", "GPU"), selection: $vm.wakeGPUChoice) {
                    Text("G4 · PRO 6000").tag("G4")
                    Text("H100 · 80GB").tag("H100")
                    Text("A100 · 80GB").tag("A100")
                    Text("L4 · 24GB").tag("L4")
                    Text("T4 · 16GB").tag("T4")
                }
                .labelsHidden()
                .frame(width: 138)
                .help(L(
                    "默认推荐 G4 (NVIDIA RTX PRO 6000 Blackwell · 96GB 显存)",
                    "Recommended: G4 (NVIDIA RTX PRO 6000 Blackwell · 96GB VRAM)"
                ))

                Button {
                    Task { await vm.wakeColabHeadless() }
                } label: {
                    HStack(spacing: 5) {
                        if vm.isWakingColab {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                        }
                        Text(vm.isWakingColab
                             ? L("唤醒部署中...", "Deploying...")
                             : L("唤醒实例并部署", "Wake & Deploy"))
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isWakingColab)
            }
        }

        DisclosureGroup(L("Cloudflare 自定义域名", "Cloudflare Custom Domain")) {
            VStack(alignment: .leading, spacing: 6) {
                Toggle(L("唤醒时使用固定域名", "Use fixed domain on wake"), isOn: $vm.useCustomDomain)
                if vm.useCustomDomain {
                    Group {
                        if vm.maskServerURL {
                            SecureField(L("HTTPS 域名", "HTTPS domain"), text: $vm.customDomainURL)
                        } else {
                            TextField("https://ai.example.com", text: $vm.customDomainURL)
                        }
                    }
                    .accessibilityLabel(L("自定义 HTTPS 域名", "Custom HTTPS domain"))
                    SecureField("Tunnel Token", text: $vm.cloudflareTunnelToken)
                        .onSubmit { vm.saveTunnelConfiguration() }
                    HStack {
                        Button(L("保存配置", "Save Configuration")) { vm.saveTunnelConfiguration() }
                        Button(L("清除 Token", "Clear Token")) { vm.clearSavedTunnelToken() }
                    }
                    if !vm.tunnelCredentialMessage.isEmpty {
                        Text(vm.tunnelCredentialMessage)
                            .foregroundStyle(.secondary)
                    }
                    Text(L(
                        "命名隧道指向 http://localhost:7860。保存配置或唤醒时将 Token 写入本机钥匙串，下次启动自动读取。",
                        "Route the named tunnel to http://localhost:7860. Save or wake stores the token in Keychain for the next launch."
                    ))
                    Text(L("固定地址不是访问鉴权，请在 Cloudflare 限制访问来源。", "A fixed URL is not authentication. Restrict access in Cloudflare."))
                        .foregroundStyle(.orange)
                }
            }
            .font(.caption)
            .textFieldStyle(.roundedBorder)
            .disabled(vm.isWakingColab)
            .padding(.top, 4)
        }
        .font(.caption)

        HStack(spacing: 6) {
            Group {
                if vm.maskServerURL {
                    SecureField(
                        L("服务地址", "Server URL"),
                        text: $vm.colabServerURL,
                        prompt: Text(L("已开启打码保护", "URL Redacted"))
                    )
                } else {
                    TextField(
                        L("服务地址", "Server URL"),
                        text: $vm.colabServerURL,
                        prompt: Text("https://ai.example.com / xxxx.gradio.live")
                    )
                }
            }
            .textFieldStyle(.roundedBorder)
            .font(.system(size: 12, design: .monospaced))

            Button {
                vm.maskServerURL.toggle()
            } label: {
                Image(systemName: vm.maskServerURL ? "eye.slash.fill" : "eye")
                    .foregroundStyle(vm.maskServerURL ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.borderless)
            .help(vm.maskServerURL
                  ? L("取消打码，显示真实隧道地址", "Reveal tunnel URL")
                  : L("录屏/截图防泄密：打码隐藏公网隧道地址", "Privacy mode: redact public tunnel URL for screenshots"))

            Button(vm.isConnected ? L("刷新", "Refresh") : L("连接", "Connect")) {
                Task { await vm.checkColabStatus() }
            }
            .controlSize(.small)
            Button {
                vm.openOnboardingGuide(step: 0)
            } label: {
                Image(systemName: "questionmark.circle")
            }
            .buttonStyle(.borderless)
            .help(L("打开新手引导与部署指南", "Open quick start & deployment guide"))
        }

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                StatusDot(color: vm.isConnected ? .green : .orange)
                Text(vm.displayGpuName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 4)
                if vm.drivePersisted {
                    Text(L("云盘持久化", "Drive Persisted"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color.primary.opacity(0.055)))
                }
                if vm.vramTotalGB > 0 || vm.ramTotalGB > 0 || vm.diskTotalGB > 0 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            vm.combinedTelemetryChartMode.toggle()
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: vm.combinedTelemetryChartMode ? "rectangle.split.1x2" : "chart.xyaxis.line")
                                .font(.system(size: 9.5, weight: .semibold))
                            Text(vm.combinedTelemetryChartMode ? L("分项", "Split") : L("同屏", "Combined"))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.11))
                        )
                    }
                    .buttonStyle(.plain)
                    .help(vm.combinedTelemetryChartMode
                          ? L("切换为显存/内存/硬盘独立折线面积图", "Switch to separate VRAM / RAM / Disk area charts")
                          : L("切换为显存/内存/硬盘三线同屏对比图", "Switch to combined 3-line telemetry comparison chart"))
                }
            }

            HStack(spacing: 8) {
                utilizationButton(title: "CPU", value: vm.cpuUtilization, gpu: false)
                utilizationButton(title: "GPU", value: vm.gpuUtilization, gpu: true)
            }

            if vm.vramTotalGB > 0 || vm.ramTotalGB > 0 || vm.diskTotalGB > 0 {
                if vm.combinedTelemetryChartMode {
                    CombinedMultiMetricChartCard(
                        vramUsed: vm.vramUsedGB,
                        vramTotal: vm.vramTotalGB,
                        vramSamples: vm.vramHistoryPct,
                        ramUsed: vm.ramUsedGB,
                        ramTotal: vm.ramTotalGB,
                        ramSamples: vm.ramHistoryPct,
                        diskUsed: vm.diskUsedGB,
                        diskTotal: vm.diskTotalGB,
                        diskSamples: vm.diskHistoryPct
                    )
                    .help(L("三线实时对比：显存 VRAM / 系统内存 RAM / 硬盘 Disk", "Live 3-metric comparison: VRAM / System RAM / Disk"))
                } else {
                    VStack(spacing: 5.5) {
                        if vm.vramTotalGB > 0 {
                            SingleMetricLineChartCard(
                                title: L("显存 VRAM", "VRAM"),
                                usedGB: vm.vramUsedGB,
                                freeGB: vm.vramFreeGB,
                                totalGB: vm.vramTotalGB,
                                samples: vm.vramHistoryPct,
                                accentColor: Color(red: 0.33, green: 0.53, blue: 0.98),
                                isWarning: vm.vramFreeGB < 8.0,
                                isCritical: vm.vramFreeGB < 3.0
                            )
                            .help(L("悬停查看历史显存占用曲线", "Hover to inspect historical GPU VRAM usage"))
                        }
                        if vm.ramTotalGB > 0 {
                            SingleMetricLineChartCard(
                                title: L("内存 RAM", "System RAM"),
                                usedGB: vm.ramUsedGB,
                                freeGB: vm.ramFreeGB,
                                totalGB: vm.ramTotalGB,
                                samples: vm.ramHistoryPct,
                                accentColor: Color(red: 0.10, green: 0.76, blue: 0.53),
                                isWarning: vm.ramFreeGB < 10.0,
                                isCritical: vm.ramFreeGB < 5.0
                            )
                            .help(L("悬停查看系统内存与热备占用曲线", "Hover to inspect system RAM & hot-standby usage"))
                        }
                        if vm.diskTotalGB > 0 {
                            SingleMetricLineChartCard(
                                title: L("硬盘 Disk", "Disk"),
                                usedGB: vm.diskUsedGB,
                                freeGB: vm.diskFreeGB,
                                totalGB: vm.diskTotalGB,
                                samples: vm.diskHistoryPct,
                                accentColor: Color(red: 0.05, green: 0.73, blue: 0.88),
                                isWarning: vm.diskFreeGB < 20.0,
                                isCritical: vm.diskFreeGB < 10.0
                            )
                            .help(L("悬停查看本地实例 NVMe 磁盘空间曲线", "Hover to inspect instance NVMe disk usage"))
                        }
                    }
                }

                if vm.shmTotalGB >= 1.0 || vm.driveTotalGB > 0 {
                    HStack(spacing: 6) {
                        if vm.shmTotalGB >= 1.0 {
                            Text(L(
                                "内存盘可用 \(fmt(vm.shmFreeGB, 1))/\(fmt(vm.shmTotalGB, 0))G",
                                "/dev/shm Free \(fmt(vm.shmFreeGB, 1))/\(fmt(vm.shmTotalGB, 0))G"
                            ))
                        }
                        Spacer()
                        if vm.driveTotalGB > 0 {
                            Text(L(
                                "云盘可用 \(fmt(vm.driveFreeGB, 1))G",
                                "Drive Free \(fmt(vm.driveFreeGB, 1))G"
                            ))
                        }
                    }
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary.opacity(0.85))
                    .monospacedDigit()
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    private var usageRows: some View {
        HStack(spacing: 0) {
            metricColumn(
                title: vm.officialCUBalance != nil ? L("账户余额", "CU Balance") : L("预计余额", "Est. Balance"),
                value: "\(fmt(vm.displayRemainingCU)) CU",
                highlight: .primary
            )
            Divider().frame(height: 28)
            metricColumn(
                title: L("扣费速率", "Burn Rate"),
                value: "\(fmt(vm.displayBurnRate)) CU/h",
                highlight: vm.displayBurnRate > 0 ? .orange : .secondary
            )
            Divider().frame(height: 28)
            metricColumn(
                title: L("本次运行", "Uptime"),
                value: vm.formattedUptime,
                highlight: .secondary
            )
        }
        .padding(.vertical, 4)

        HStack {
            Text(L("闲置自动释放", "Idle Auto-Sleep"))
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Picker(L("闲置自动释放", "Idle Auto-Sleep"), selection: Binding(
                get: { vm.idleTimeoutMinutes },
                set: { newVal in Task { await vm.updateIdleTimeoutConfig(newVal) } }
            )) {
                Text(L("15 分钟", "15m")).tag(15)
                Text(L("30 分钟", "30m")).tag(30)
                Text(L("60 分钟", "60m")).tag(60)
                Text(L("关闭", "Off")).tag(0)
            }
            .labelsHidden()
            .controlSize(.small)
            .frame(width: 105)
        }

        if vm.isConnected && vm.idleTimeoutMinutes > 0 {
            Text(vm.formattedIdleRemaining)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }

        Button(role: .destructive) {
            vm.showDisconnectConfirm = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "power")
                    .font(.caption)
                Text(vm.activeVMCount > 0
                     ? L("释放全部实例 (\(vm.activeVMCount) 台运行中)", "Release All Instances (\(vm.activeVMCount) Running)")
                     : L("释放全部实例", "Release All Instances"))
            }
            .frame(maxWidth: .infinity)
        }
        .controlSize(.small)
    }

    private func metricColumn(title: String, value: String, highlight: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(highlight)
                .monospacedDigit()
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func openModelHubRows(palette: StudioPalette) -> some View {
        VStack(spacing: 5) {
            ForEach(OPEN_MODEL_CATALOG) { spec in
                let isSelected = vm.selectedModelId == spec.id
                let isLoaded = vm.loadedModelIds.contains(spec.id) || (vm.loadedModelId == spec.id && vm.modelLoaded)
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        vm.switchSelectedModel(spec)
                    }
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: spec.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : Color.accentColor)
                            .frame(width: 26, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.12))
                            )

                        VStack(alignment: .leading, spacing: 1.5) {
                            HStack(spacing: 5) {
                                Text(spec.name)
                                    .font(.system(size: 12.5, weight: .semibold))
                                    .foregroundStyle(.primary)
                                if spec.modality == .comfyUI && vm.comfyRunning {
                                    Text(vm.comfyQueueRunning > 0 ? L("渲染中", "Rendering") : L("画布在线", "Canvas Live"))
                                        .font(.system(size: 9.5, weight: .bold))
                                        .foregroundStyle(Color.green)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Capsule().fill(Color.green.opacity(0.15)))
                                } else if isLoaded {
                                    Text(L("显存常驻", "In VRAM"))
                                        .font(.system(size: 9.5, weight: .bold))
                                        .foregroundStyle(Color.green)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Capsule().fill(Color.green.opacity(0.15)))
                                }
                            }
                            Text(spec.badge)
                                .font(.system(size: 10.5))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 4)
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.accentColor.opacity(0.11) : palette.inputFill.opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isSelected ? Color.accentColor.opacity(0.55) : Color.clear, lineWidth: 1)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }

        if !vm.loadedModelsDetail.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "memorychip.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.green)
                    Text(L(
                        "GPU 显存共驻模型 (\(vm.loadedModelsDetail.count))",
                        "Co-Resident in VRAM (\(vm.loadedModelsDetail.count))"
                    ))
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if vm.loadedModelsDetail.count > 1 {
                        Button(L("全部释放", "Unload All")) {
                            Task { await vm.unloadRemoteModelFromVRAM(modelId: "all") }
                        }
                        .buttonStyle(.borderless)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.red)
                        .disabled(vm.isUnloadingModel)
                    }
                }
                ForEach(vm.loadedModelsDetail) { item in
                    HStack(spacing: 6) {
                        StatusDot(color: .green)
                        Text(item.localizedName)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        if let ctx = item.context_length, ctx > 0 {
                            Text("\(ctx / 1024)K")
                                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.accentColor)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                        }
                        if let gb = item.vram_gb, gb > 0 {
                            Text("~\(fmt(gb, 1))G")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        Button {
                            Task { await vm.unloadRemoteModelFromVRAM(modelId: item.id) }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help(L("从 GPU 显存卸载 \(item.localizedName)", "Unload \(item.localizedName) from GPU VRAM"))
                        .disabled(vm.isUnloadingModel)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(palette.inputFill))
                }
            }
            .padding(.top, 2)
        }

        Divider().padding(.vertical, 2)

        if vm.activeModelSpec.modality == .comfyUI {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(L("画布状态", "Canvas Status"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(vm.comfyRunning
                         ? L("在线 (端口 8188)", "Online (Port 8188)")
                         : (vm.comfyStarting ? L("部署启动中...", "Starting...") : L("未启动", "Stopped")))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(vm.comfyRunning ? Color.green : (vm.comfyStarting ? Color.orange : Color.secondary))
                }
                if vm.comfyStarting || vm.comfyDownloadingWeight {
                    ProgressView(value: vm.comfyProgress, total: 1.0)
                }
                HStack(spacing: 6) {
                    if vm.comfyRunning && !vm.comfyPublicURL.isEmpty {
                        Button {
                            vm.openComfyUIInBrowser()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "safari")
                                Text(L("打开画布", "Open Canvas"))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)

                        Button {
                            Task { await vm.stopRemoteComfyUI() }
                        } label: {
                            Image(systemName: "stop.fill")
                        }
                        .controlSize(.regular)
                        .help(L("同步云盘并停止 ComfyUI 进程", "Sync to Google Drive & stop ComfyUI process"))
                    } else {
                        Button {
                            Task { await vm.startRemoteComfyUI(forceRestart: false, autoOpenBrowser: true) }
                        } label: {
                            HStack(spacing: 4) {
                                if vm.comfyStarting {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "play.circle.fill")
                                }
                                Text(vm.comfyStarting ? L("正在部署...", "Deploying...") : L("启动 ComfyUI 画布", "Start ComfyUI Canvas"))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .disabled(!vm.isConnected || vm.comfyStarting)
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(L("HF 仓库", "HF Repo"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        if let hfURL = URL(string: "https://huggingface.co/\(vm.activeModelSpec.repoId)") {
                            NSWorkspace.shared.open(hfURL)
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Text(vm.activeModelSpec.repoId)
                                .font(.system(size: 10.5, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 9.5))
                        }
                        .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help(L("在浏览器打开 HuggingFace 模型仓库", "Open HuggingFace model repository in browser"))
                }

                HStack {
                    Text(L("磁盘权重", "Disk Weights"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(vm.allDownloaded
                         ? L("已就绪 \(vm.downloadedCount)/\(vm.totalFileCount) (\(fmt(vm.totalDiskSizeGB, 1)) GB)",
                             "Ready \(vm.downloadedCount)/\(vm.totalFileCount) (\(fmt(vm.totalDiskSizeGB, 1)) GB)")
                         : L("\(vm.downloadedCount)/\(vm.totalFileCount) 个文件",
                             "\(vm.downloadedCount)/\(vm.totalFileCount) files"))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(vm.allDownloaded ? Color.green : Color.secondary)
                        .monospacedDigit()
                }

                DisclosureGroup(
                    L("查看权重分片 (\(vm.modelFiles.count))", "View Weight Shards (\(vm.modelFiles.count))"),
                    isExpanded: $showFileList
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        ScrollView {
                            VStack(spacing: 4) {
                                ForEach(vm.modelFiles) { file in
                                    HStack(spacing: 5) {
                                        Image(systemName: file.exists ? "checkmark.circle.fill" : "circle.dashed")
                                            .foregroundStyle(file.exists ? Color.green : Color.secondary)
                                            .font(.system(size: 10))
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(file.name)
                                                .font(.system(size: 10.5, design: .monospaced))
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                            if let desc = file.localizedDesc, !desc.isEmpty {
                                                Text(desc)
                                                    .font(.system(size: 9.5))
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        Spacer()
                                        Text(file.exists ? "\(fmt(file.size_gb, 1))G" : L("未下", "Pending"))
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                            .monospacedDigit()
                                    }
                                    .help(file.localizedDesc ?? file.name)
                                }
                            }
                            .padding(.top, 4)
                        }
                        .frame(maxHeight: 125)

                        HStack(spacing: 6) {
                            Text("HF Token")
                                .font(.system(size: 10.5))
                                .foregroundStyle(.secondary)
                            SecureField(
                                "HF Token",
                                text: $vm.hfToken,
                                prompt: Text(L("可选，加速下载或访问受限仓库", "Optional, faster / gated repos"))
                            )
                            .textFieldStyle(.roundedBorder)
                            .controlSize(.small)
                            .font(.system(size: 11, design: .monospaced))
                            .onSubmit { vm.saveHFToken() }
                            Button(L("保存", "Save")) { vm.saveHFToken() }
                                .controlSize(.small)
                                .disabled(vm.hfToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .help(L("保存 HF Token 至本机钥匙串", "Save HF Token to this Mac's Keychain"))
                            Button(L("清除", "Clear")) { vm.clearSavedHFToken() }
                                .controlSize(.small)
                                .help(L("仅删除本地 HF Token", "Delete only the local HF Token"))
                        }
                        if !vm.hfCredentialMessage.isEmpty {
                            Text(vm.hfCredentialMessage)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .font(.caption)

                if vm.activeModelSpec.modality == .llmVLM {
                    let presetKs = [8, 16, 32, 64, 128, 192, 256]
                    let pickerKs = presetKs.contains(vm.contextLengthK)
                        ? presetKs
                        : (presetKs + [vm.contextLengthK]).sorted()

                    HStack {
                        Text(L("上下文长度", "Context Length"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker(L("上下文长度", "Context Length"), selection: Binding(
                            get: { vm.contextLengthK },
                            set: { newK in
                                vm.contextLengthK = newK.clamped(to: 4...256)
                                Task { await vm.syncContextLengthToColab(announce: true) }
                            }
                        )) {
                            ForEach(pickerKs, id: \.self) { k in
                                Text(k == 256 ? L("256K (最大)", "256K (Max)") : "\(k)K (\(k * 1024))").tag(k)
                            }
                        }
                        .labelsHidden()
                        .controlSize(.small)
                        .frame(width: 148)
                    }

                    if vm.selectedModelId == "qwen38_27b_gguf",
                       vm.isSelectedModelLoadedInVRAM,
                       vm.loadedContextLengthTokens > 0,
                       vm.loadedContextLengthTokens != vm.contextLengthTokens {
                        Text(L(
                            "当前显存 KV 为 \(vm.loadedContextLengthTokens / 1024)K，点「重新装载」切换至 \(vm.contextLengthK)K",
                            "VRAM KV cache is \(vm.loadedContextLengthTokens / 1024)K; click 'Reload' to apply \(vm.contextLengthK)K"
                        ))
                            .font(.system(size: 10.5))
                            .foregroundStyle(.orange)
                    } else if vm.selectedModelId == "qwen38_27b_gguf", vm.contextLengthK >= 128 {
                        Text(L(
                            "提示：日常对话选 32K/64K 可达峰值 90~110 tok/s；256K 预分配超长槽位约为 80+ tok/s",
                            "Tip: 32K/64K hits peak 90–110 tok/s; 256K pre-allocated context runs at ~80+ tok/s"
                        ))
                            .font(.system(size: 10.5))
                            .foregroundStyle(.secondary)
                    }
                }

                if !vm.isConnected {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                        Text(L("Colab 实例离线（已闲置释放或未连接）", "Colab offline (idle-released or disconnected)"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.orange)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        if vm.cliLoggedIn {
                            Button(vm.isWakingColab ? L("唤醒中...", "Waking...") : L("一键唤醒", "Wake")) {
                                Task { await vm.wakeColabHeadless() }
                            }
                            .controlSize(.mini)
                            .buttonStyle(.borderedProminent)
                            .disabled(vm.isWakingColab)
                        } else if !vm.normalizedBaseURL.isEmpty {
                            Button(L("重连", "Reconnect")) {
                                Task { await vm.checkColabStatus() }
                            }
                            .controlSize(.mini)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color.orange.opacity(0.10)))
                }

                if vm.downloadTotalBytes > 0 {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(String(format: L("下载/复用：%.2f / %.2f GiB", "Download / reuse: %.2f / %.2f GiB"), vm.downloadCompletedBytes / 1073741824, vm.downloadTotalBytes / 1073741824))
                        ProgressView(value: min(1, max(0, vm.downloadCompletedBytes / vm.downloadTotalBytes)))
                        if vm.uploadTotalBytes > 0 {
                            Text(String(format: vm.uploadLive ? L("Drive 已发送：%.2f / %.2f GiB", "Drive sent: %.2f / %.2f GiB") : L("Drive 已确认：%.2f / %.2f GiB", "Drive confirmed: %.2f / %.2f GiB"), vm.uploadCompletedBytes / 1073741824, vm.uploadTotalBytes / 1073741824))
                            ProgressView(value: min(1, max(0, vm.uploadCompletedBytes / vm.uploadTotalBytes)))
                                .tint(vm.drivePersisted ? .green : .orange)
                            Text(String(format: L("远端已确认：%.2f GiB（发送 100%% 不代表校验通过）", "Remote confirmed: %.2f GiB (100%% sent is not verification)"), vm.uploadConfirmedBytes / 1073741824))
                            if !vm.uploadLive {
                                Text(L("旧挂载：只计已上传完整文件，不含进行中的分片。", "Legacy mount: completed uploads only, excluding in-flight bytes."))
                            }
                            Text(vm.drivePersisted ? L("已持久化 · 远端校验通过", "Persisted · remote verification passed") : L("尚未确认持久化 · 请勿释放实例", "Persistence unconfirmed · do not release runtime"))
                                .foregroundStyle(vm.drivePersisted ? Color.green : Color.orange)
                            if vm.uploadState == "unavailable" || vm.uploadState == "error" {
                                Text(L("远端校验不可用或失败，检查挂载/授权后点「校验权重」重试。", "Remote verification unavailable or failed. Check mount/auth, then retry Verify Weights."))
                            }
                        }
                    }
                    .font(.system(size: 10))
                    .fixedSize(horizontal: false, vertical: true)
                    .help(vm.transferMessage)
                }
                if vm.isLoadingModel || (vm.isDownloadingWeights && vm.downloadTotalBytes <= 0) {
                    ProgressView(value: vm.modelTaskProgress, total: 1.0)
                }

                HStack(spacing: 6) {
                    Button {
                        Task { await vm.startRemoteDownloadWeights() }
                    } label: {
                        HStack(spacing: 4) {
                            if vm.isDownloadingWeights {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "arrow.down.circle")
                            }
                            Text(vm.isDownloadingWeights
                                 ? L("下载中...", "Downloading...")
                                 : (vm.allDownloaded ? L("校验权重", "Verify Weights") : L("下载权重", "Download Weights")))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .controlSize(.regular)
                    .disabled(!vm.isConnected || vm.isDownloadingWeights || vm.isLoadingModel || vm.isUnloadingModel)

                    Button {
                        Task { await vm.loadRemoteModelToVRAM() }
                    } label: {
                        HStack(spacing: 4) {
                            if vm.isLoadingModel {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "memorychip")
                            }
                            Text(vm.isLoadingModel
                                 ? L("装载中...", "Loading...")
                                 : (vm.isSelectedModelLoadedInVRAM ? L("重新装载", "Reload") : L("加载到显存", "Load to VRAM")))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(!vm.isConnected || vm.isDownloadingWeights || vm.isLoadingModel || vm.isUnloadingModel)

                    if vm.isSelectedModelLoadedInVRAM {
                        Button {
                            Task { await vm.unloadRemoteModelFromVRAM(modelId: vm.selectedModelId) }
                        } label: {
                            Image(systemName: "eject.fill")
                        }
                        .controlSize(.regular)
                        .help(L("将当前模型从 GPU 显存中卸载释放", "Unload active model from GPU VRAM"))
                        .disabled(vm.isUnloadingModel)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var adaptiveParamRows: some View {
        switch vm.activeModelSpec.modality {
        case .comfyUI:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(L("持久化架构", "Persistence"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(vm.displayComfyPersistenceLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(vm.comfyDrivePersisted ? Color.green : Color.secondary)
                }

                HStack {
                    Text(L("已存节点 / 权重", "Saved Nodes / Weights"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(L(
                        "\(vm.comfyCustomNodesCount) 个节点 · \(vm.comfyModelsCount) 个权重",
                        "\(vm.comfyCustomNodesCount) nodes · \(vm.comfyModelsCount) weights"
                    ))
                        .font(.caption.weight(.medium))
                        .monospacedDigit()
                }

                HStack {
                    Text(L("画布执行队列", "Execution Queue"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(L(
                        "运行 \(vm.comfyQueueRunning) · 排队 \(vm.comfyQueuePending)",
                        "Running \(vm.comfyQueueRunning) · Pending \(vm.comfyQueuePending)"
                    ))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(vm.comfyQueueRunning > 0 ? Color.green : .secondary)
                        .monospacedDigit()
                }

                Toggle(L("启动前释放其它常驻模型显存", "Unload other VRAM models before starting"), isOn: $vm.comfyUnloadOthersOnStart)
                    .font(.caption)

                HStack(spacing: 6) {
                    Button {
                        Task { await vm.syncRemoteComfyUIToDrive() }
                    } label: {
                        HStack(spacing: 4) {
                            if vm.comfySyncingDrive {
                                ProgressView().controlSize(.mini)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath.icloud")
                            }
                            Text(vm.comfySyncingDrive ? L("同步中...", "Syncing...") : L("立即同步云盘", "Sync to Drive"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .controlSize(.small)
                    .disabled(!vm.isConnected || vm.comfySyncingDrive)

                    Button {
                        Task { await vm.freeRemoteComfyUIVRAM() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "memorychip")
                            Text(L("清缓存显存", "Free VRAM Cache"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .controlSize(.small)
                    .disabled(!vm.isConnected || !vm.comfyRunning)
                }
            }

        case .llmVLM:
            Toggle(L("启用深度思考链 (Thinking Mode)", "Enable Thinking Chain (Thinking Mode)"), isOn: $vm.enableThinking)
                .font(.callout)

            if vm.enableThinking {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(L("思考深度 (Reasoning Effort)", "Reasoning Effort"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(vm.reasoningEffort.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.accentColor)
                    }
                    HStack(spacing: 4) {
                        ForEach([
                            ("low", L("精简", "Low")),
                            ("medium", L("均衡", "Med")),
                            ("high", L("深入", "High")),
                            ("xhigh", L("极深", "XHigh"))
                        ], id: \.0) { (key, title) in
                            let active = vm.reasoningEffort == key
                            Button {
                                vm.reasoningEffort = key
                            } label: {
                                Text(title)
                                    .font(.system(size: 10.5, weight: active ? .bold : .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 3.5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(active ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.05))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .strokeBorder(active ? Color.accentColor.opacity(0.65) : Color.clear, lineWidth: 1)
                                    )
                                    .foregroundStyle(active ? Color.accentColor : Color.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    Text(L("上下文窗口 (最高 256K)", "Context Window (Up to 256K)"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField(
                        "K",
                        value: Binding(
                            get: { vm.contextLengthK },
                            set: { vm.contextLengthK = $0.clamped(to: 4...256) }
                        ),
                        format: .number
                    )
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)
                    .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                    .onSubmit {
                        Task { await vm.syncContextLengthToColab(announce: true) }
                    }
                    Text("K")
                        .font(.caption.weight(.semibold))
                    Stepper(
                        "",
                        value: Binding(
                            get: { vm.contextLengthK },
                            set: { newK in
                                vm.contextLengthK = newK.clamped(to: 4...256)
                                Task { await vm.syncContextLengthToColab(announce: true) }
                            }
                        ),
                        in: 4...256,
                        step: 4
                    )
                    .labelsHidden()
                    .controlSize(.small)
                }

                Slider(
                    value: Binding(
                        get: { Double(vm.contextLengthK) },
                        set: { vm.contextLengthK = Int(($0 / 4.0).rounded() * 4.0).clamped(to: 4...256) }
                    ),
                    in: 4...256,
                    onEditingChanged: { editing in
                        if !editing {
                            Task { await vm.syncContextLengthToColab(announce: true) }
                        }
                    }
                )

                HStack(spacing: 4) {
                    ForEach([8, 16, 32, 64, 128, 256], id: \.self) { k in
                        let active = vm.contextLengthK == k
                        Button {
                            vm.contextLengthK = k
                            Task { await vm.syncContextLengthToColab(announce: true) }
                        } label: {
                            Text("\(k)K")
                                .font(.system(size: 10, weight: active ? .bold : .medium, design: .monospaced))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(active ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .strokeBorder(active ? Color.accentColor.opacity(0.65) : Color.clear, lineWidth: 1)
                                )
                                .foregroundStyle(active ? Color.accentColor : Color.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(L(
                    "总容量 \(vm.contextLengthTokens) Tokens" + (vm.loadedContextLengthTokens > 0 ? " · 当前已加载 \(vm.loadedContextLengthTokens / 1024)K" : ""),
                    "Capacity \(vm.contextLengthTokens) tokens" + (vm.loadedContextLengthTokens > 0 ? " · Loaded \(vm.loadedContextLengthTokens / 1024)K" : "")
                ))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(L("最大输出长度 (含思考链)", "Max Output Tokens (incl. Thinking)"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(vm.maxNewTokens)) Tokens")
                        .font(.caption.weight(.medium))
                        .monospacedDigit()
                }
                Slider(
                    value: Binding(
                        get: { vm.maxNewTokens },
                        set: { vm.maxNewTokens = (($0 / 512).rounded() * 512).clamped(to: 1024...65536) }
                    ),
                    in: 1024...65536
                )
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(L("采样温度 (Temperature)", "Temperature"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(fmt(vm.temperature, 2)) · Top-P \(fmt(vm.topP, 2)) · Top-K 20")
                        .font(.caption.weight(.medium))
                        .monospacedDigit()
                }
                Slider(value: $vm.temperature, in: 0.1...1.5)
            }

            Button {
                vm.chatHistory.removeAll()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.caption)
                    Text(L("清空多轮对话历史", "Clear Chat History"))
                }
                .frame(maxWidth: .infinity)
            }
            .controlSize(.small)
            .disabled(vm.chatHistory.isEmpty || vm.isGenerating)

        case .image:
            VStack(alignment: .leading, spacing: 4) {
                Text(L("输出画幅", "Output Aspect & Resolution"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker(L("画幅", "Resolution"), selection: $vm.selectedImageResolution) {
                    ForEach(IMAGE_RESOLUTIONS) { opt in
                        Text(opt.label).tag(opt)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(L("采样步数", "Sampling Steps"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(L("\(Int(vm.inferenceSteps)) 步", "\(Int(vm.inferenceSteps)) steps"))
                        .font(.caption.weight(.medium))
                        .monospacedDigit()
                }
                Slider(
                    value: Binding(
                        get: { vm.inferenceSteps },
                        set: { vm.inferenceSteps = $0.rounded().clamped(to: 4...50) }
                    ),
                    in: 4...50
                )
            }

            if vm.selectedModelId == "z_image_turbo" && vm.taskModeId == "i2i_edit" {
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(L("重绘幅度", "Denoising Strength"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(fmt(vm.denoisingStrength, 2))
                            .font(.caption.weight(.medium))
                            .monospacedDigit()
                    }
                    Slider(value: $vm.denoisingStrength, in: 0.20...1.0)
                }
            }

            seedAndBatchControls(unitLabelZh: "张")

        case .videoAudio, .video:
            VStack(alignment: .leading, spacing: 4) {
                Text(L("视频分辨率", "Video Resolution"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker(L("分辨率", "Resolution"), selection: $vm.selectedVideoResolution) {
                    ForEach(VIDEO_RESOLUTIONS) { opt in
                        Text(opt.label).tag(opt)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(L("视频总帧数 (4~15 秒)", "Total Frames (4–15s)"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(L(
                        "\(Int(vm.numFrames)) 帧 · 约 \(fmt(vm.numFrames / vm.fps, 1)) 秒",
                        "\(Int(vm.numFrames)) frames · ~\(fmt(vm.numFrames / vm.fps, 1))s"
                    ))
                        .font(.caption.weight(.medium))
                        .monospacedDigit()
                }
                Slider(
                    value: Binding(
                        get: { vm.numFrames },
                        set: { vm.numFrames = (((($0 - 5) / 17).rounded() * 17) + 5).clamped(to: 90...362) }
                    ),
                    in: 90...362
                )
                HStack(spacing: 4) {
                    ForEach([(90, "4s"), (124, "5s"), (192, "8s"), (243, "10s"), (294, "12s"), (362, "15s")], id: \.0) { frames, tag in
                        let isSel = Int(vm.numFrames) == frames
                        Button {
                            vm.numFrames = Double(frames)
                        } label: {
                            Text(tag)
                                .font(.system(size: 10, weight: isSel ? .semibold : .regular, design: .monospaced))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 2.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(isSel ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.10))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .stroke(isSel ? Color.accentColor.opacity(0.55) : Color.clear, lineWidth: 1)
                                )
                                .foregroundStyle(isSel ? Color.accentColor : Color.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(L("采样步数", "Sampling Steps"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(L("\(Int(vm.inferenceSteps)) 步", "\(Int(vm.inferenceSteps)) steps"))
                        .font(.caption.weight(.medium))
                        .monospacedDigit()
                }
                Slider(
                    value: Binding(
                        get: { vm.inferenceSteps },
                        set: { vm.inferenceSteps = (($0 / 5).rounded() * 5).clamped(to: 10...60) }
                    ),
                    in: 10...60
                )
            }

            seedAndBatchControls(unitLabelZh: "条")
        }
    }

    @ViewBuilder
    private func seedAndBatchControls(unitLabelZh: String) -> some View {
        HStack {
            Text(L("随机种子", "Seed"))
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            TextField(L("种子", "Seed"), value: $vm.seed, format: .number.grouping(.never))
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)
                .frame(width: 96)
                .disabled(vm.randomizeSeed)
            Toggle(L("随机", "Random"), isOn: $vm.randomizeSeed)
                .toggleStyle(.checkbox)
                .font(.caption)
        }

        HStack(spacing: 8) {
            Text(L("批量连抽", "Batch Size"))
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            HStack(spacing: 2) {
                ForEach([1, 2, 3, 4], id: \.self) { count in
                    let isSelected = vm.batchCount == count
                    Button {
                        withAnimation(.easeInOut(duration: 0.14)) {
                            vm.batchCount = count
                        }
                    } label: {
                        Text(L("\(count) \(unitLabelZh)", "\(count)×"))
                            .font(.system(size: 11.5, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isSelected ? Color.accentColor : Color.clear)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .frame(width: 192)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.06))
            )
        }
    }

    // MARK: - 右侧主工作区

    private func workspacePanel(palette: StudioPalette) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 1. 顶部模型概览与醒目卡片模式切换栏
                modeSwitcherHeader(palette: palette)

                if vm.activeModelSpec.modality == .comfyUI {
                    comfyUIWorkspaceSection(palette: palette)
                } else if vm.taskModeId == "api" {
                    // API 协议网关专属面板（OpenAI + Anthropic 双协议配置与一键复制）
                    apiGatewaySection(palette: palette)
                } else {
                    // 2. 参考图上传区（在首尾帧、图生视频、指令修图、视觉理解模式下自动展开）
                    if ["fl2va", "i2v", "i2i_edit", "vlm"].contains(vm.taskModeId) {
                        referenceImageSection
                    }

                    // 3. 提示词与输入工作台
                    promptComposerSection(palette: palette)

                    // 4. 生成主按钮与状态条
                    generateActionSection

                    // 5. 自适应预览区（大模型流式对话区 或 视频/图像播放器 + 历史库）
                    if vm.activeModelSpec.modality == .llmVLM {
                        llmConversationCard(palette: palette)
                    } else {
                        HStack(alignment: .top, spacing: 14) {
                            mediaPreviewCard
                            mediaHistoryCard.frame(width: 242)
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 1180)
            .frame(maxWidth: .infinity)
        }
        .compatScrollIndicatorMargins(.vertical, 6)
    }

    // MARK: - ComfyUI 云端节点视频工作台与 Google Drive 软链持久化面板

    @ViewBuilder
    private func comfyUIWorkspaceSection(palette: StudioPalette) -> some View {
        let modelSubfolders = [
            ("diffusion_models", L("diffusion_models (DiT / 视频主干模型)", "diffusion_models (DiT / Video Backbones)")),
            ("checkpoints", L("checkpoints (完整大模型)", "checkpoints (Full Checkpoints)")),
            ("loras", L("loras (LoRA 风格/运镜微调)", "loras (Style & Camera LoRAs)")),
            ("vae", L("vae (3D 视频 / 图像 VAE)", "vae (3D Video / Image VAE)")),
            ("text_encoders", L("text_encoders (UMT5 / Qwen / CLIP 编码器)", "text_encoders (UMT5 / Qwen / CLIP)")),
            ("clip_vision", L("clip_vision (首尾帧 / 图生视频视觉编码器)", "clip_vision (I2V / FLF2V Vision Encoders)")),
            ("controlnet", L("controlnet (姿态 / 深度 / VACE 控制)", "controlnet (Pose / Depth / VACE)")),
            ("upscale_models", L("upscale_models (高清超分放大)", "upscale_models (Super-Resolution Upscalers)")),
            ("audio_encoders", L("audio_encoders (音频驱动 / 配音节点)", "audio_encoders (Audio-Driven / Foley Nodes)")),
            ("gguf", L("gguf (量化视频/图像主干)", "gguf (Quantized Video / Image Backbones)"))
        ]

        // 1. 核心画布拉起与全屏浏览器入口卡片
        WorkspaceCard(
            title: L("云端 ComfyUI 全屏节点画布", "Cloud ComfyUI Fullscreen Node Canvas"),
            subtitle: L(
                "预装 ComfyUI + ComfyUI-Manager + VideoHelperSuite，自动复用 EasyColab 的 G4 保活、显存/内存/磁盘折线监控与自动休眠",
                "Preinstalled with ComfyUI + ComfyUI-Manager + VideoHelperSuite, sharing EasyColab's G4 keep-alive, live VRAM/RAM/Disk telemetry & idle auto-sleep"
            ),
            icon: "point.3.connected.trianglepath.dotted",
            trailing: AnyView(
                HStack(spacing: 6) {
                    StatusDot(color: vm.comfyRunning ? .green : (vm.comfyStarting ? .orange : .secondary.opacity(0.45)))
                    Text(vm.comfyRunning
                         ? (vm.comfyQueueRunning > 0
                            ? L("队列渲染中 (\(vm.comfyQueueRunning) 运行 / \(vm.comfyQueuePending) 排队)",
                                "Rendering (\(vm.comfyQueueRunning) active / \(vm.comfyQueuePending) queued)")
                            : L("画布在线待命", "Canvas Ready"))
                         : (vm.comfyStarting ? L("正在部署启动...", "Starting...") : L("未启动", "Stopped")))
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(vm.comfyRunning ? Color.green : (vm.comfyStarting ? Color.orange : .secondary))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.primary.opacity(0.06)))
            )
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    if vm.comfyRunning && !vm.comfyPublicURL.isEmpty {
                        Button {
                            vm.openComfyUIInBrowser()
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: "safari.fill")
                                Text(L("在浏览器打开全屏节点画布", "Open Fullscreen Canvas in Browser"))
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button {
                            copyToPasteboard(
                                vm.comfyPublicURL,
                                tip: L("已复制 ComfyUI 公网画布地址到剪贴板", "Copied ComfyUI public canvas URL to clipboard")
                            )
                        } label: {
                            Label(L("复制画布链接", "Copy Canvas URL"), systemImage: "doc.on.doc")
                                .padding(.vertical, 8)
                        }
                        .controlSize(.large)

                        Button {
                            Task { await vm.startRemoteComfyUI(forceRestart: true, autoOpenBrowser: false) }
                        } label: {
                            Label(L("重启生效", "Restart"), systemImage: "arrow.clockwise")
                                .padding(.vertical, 8)
                        }
                        .controlSize(.large)
                        .disabled(vm.comfyStarting)
                        .help(L(
                            "在 Manager 安装新自定义节点后可点击一键重启并自动持久化至云盘",
                            "Restart ComfyUI after installing custom nodes in Manager and auto-sync to Google Drive"
                        ))
                    } else {
                        Button {
                            Task { await vm.startRemoteComfyUI(forceRestart: false, autoOpenBrowser: true) }
                        } label: {
                            HStack(spacing: 8) {
                                if vm.comfyStarting {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "bolt.circle.fill")
                                }
                                Text(vm.comfyStarting
                                     ? L("正在部署云端 ComfyUI 并恢复 Google Drive 软链与节点...",
                                         "Deploying Cloud ComfyUI & restoring Google Drive symlinks and custom nodes...")
                                     : (vm.isConnected
                                        ? L("一键拉起云端 ComfyUI 并在浏览器打开全屏画布", "Deploy & Open Fullscreen Cloud ComfyUI Canvas")
                                        : L("请先在左侧唤醒或连接 G4 实例", "Wake or connect a G4 instance on the left first")))
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(!vm.isConnected || vm.comfyStarting)
                    }
                }

                if vm.comfyStarting || vm.comfyDownloadingWeight {
                    ProgressView(value: vm.comfyProgress, total: 1.0)
                }

                HStack(spacing: 8) {
                    Image(systemName: vm.comfyRunning ? "checkmark.shield.fill" : "info.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(vm.comfyRunning ? Color.green : Color.accentColor)
                    Text(vm.displayComfyStatusMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Spacer()
                    if vm.comfyRunning && !vm.comfyPublicURL.isEmpty {
                        Text(vm.maskedURLDisplay(vm.comfyPublicURL))
                            .font(.system(size: 11.5, design: .monospaced))
                            .foregroundStyle(Color.accentColor)
                            .textSelection(.enabled)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 8).fill(palette.inputFill))
            }
        }

        // 2. 新手零门槛预置图生视频 / 首尾帧运镜工作流包卡片
        WorkspaceCard(
            title: L(
                "预置图生视频 / 首尾帧运镜工作流包（一键配齐模型与中文画布）",
                "Preset Image-to-Video & First/Last Frame Workflow Packs (1-Click Setup)"
            ),
            subtitle: L(
                "专为零基础设计：一键 8 线程下齐配套权重、自动生成全中文三步注释工作流并将 ComfyUI 设为简体中文，零红框报错直接出片",
                "Turnkey setup: 8-thread download of all required weights plus annotated 3-step workflow templates — zero missing-node errors"
            ),
            icon: "wand.and.stars",
            trailing: AnyView(
                Text(L(
                    "已就绪 \(vm.comfyPresetPacks.filter(\.ready).count) / \(vm.comfyPresetPacks.count) 套",
                    "Ready \(vm.comfyPresetPacks.filter(\.ready).count) / \(vm.comfyPresetPacks.count)"
                ))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(vm.comfyPresetPacks.contains(where: \.ready) ? Color.green : .secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.primary.opacity(0.06)))
            )
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // 三步傻瓜引导条
                HStack(spacing: 8) {
                    comfyStepChip(
                        num: "1",
                        title: L("点击下方「一键配齐模型与工作流」", "Click '1-Click Install Pack' below"),
                        icon: "arrow.down.circle.fill",
                        palette: palette
                    )
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary.opacity(0.6))
                    comfyStepChip(
                        num: "2",
                        title: L("在画布最左侧点「工作流」选中文模板", "Open 'Workflows' sidebar & pick template"),
                        icon: "sidebar.left",
                        palette: palette
                    )
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary.opacity(0.6))
                    comfyStepChip(
                        num: "3",
                        title: L("上传 1~2 张图片点右上角「运行」出片", "Upload 1–2 images & click 'Run'"),
                        icon: "play.circle.fill",
                        palette: palette
                    )
                }

                VStack(spacing: 10) {
                    ForEach(vm.comfyPresetPacks) { pack in
                        comfyPresetPackRow(pack, palette: palette)
                    }
                }
            }
        }

        // 3. Google Drive 自动软链持久化矩阵卡片
        WorkspaceCard(
            title: L("Google Drive 自动软链与跨实例持久化", "Google Drive Auto-Symlink Persistence Across Instances"),
            subtitle: L(
                "新开 G4 实例自动挂载恢复自定义节点（含自动补齐 Python requirements.txt 依赖）、模型权重与工作流，免重复安装",
                "Fresh G4 runtimes automatically restore custom nodes (including Python requirements.txt), model weights, and saved workflows"
            ),
            icon: "externaldrive.badge.icloud",
            trailing: AnyView(
                Button {
                    Task { await vm.syncRemoteComfyUIToDrive() }
                } label: {
                    HStack(spacing: 4) {
                        if vm.comfySyncingDrive {
                            ProgressView().controlSize(.mini)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text(vm.comfySyncingDrive ? L("正在同步...", "Syncing...") : L("立即同步至云盘", "Sync to Drive Now"))
                    }
                }
                .controlSize(.small)
                .disabled(!vm.isConnected || vm.comfySyncingDrive)
            )
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    comfyPersistMetricTile(
                        title: L("models/* 模型权重库", "models/* Weight Library"),
                        value: L("\(vm.comfyModelsCount) 个权重文件", "\(vm.comfyModelsCount) weight files"),
                        detail: L("各子目录自动软链至云盘，新节点自建目录自动接管", "Subfolders symlinked to Drive; new node folders auto-adopted"),
                        icon: "cube.box.fill",
                        palette: palette
                    )
                    comfyPersistMetricTile(
                        title: L("custom_nodes 自定义节点", "custom_nodes Extensions"),
                        value: L("\(vm.comfyCustomNodesCount) 个节点插件", "\(vm.comfyCustomNodesCount) custom nodes"),
                        detail: L("NVMe 高速运行 + 云盘双向镜像 + 自动重装依赖", "Local NVMe speed + two-way Drive mirror + auto pip deps"),
                        icon: "puzzlepiece.extension.fill",
                        palette: palette
                    )
                    comfyPersistMetricTile(
                        title: L("workflows 工作流存档", "workflows Saved Graphs"),
                        value: L("\(vm.comfyWorkflowsCount) 份工作流", "\(vm.comfyWorkflowsCount) workflows"),
                        detail: L("画布 Ctrl+S 保存即自动持久化至 Google Drive", "Saving with Ctrl+S in canvas persists directly to Google Drive"),
                        icon: "flowchart.fill",
                        palette: palette
                    )
                }

                HStack(spacing: 6) {
                    Text(L("云端持久化根路径:", "Drive Persistence Root:"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(vm.comfyPersistRoot)
                        .font(.system(size: 11.5, design: .monospaced))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                    Spacer()
                    Text(vm.displayComfyPersistenceLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(vm.comfyDrivePersisted ? Color.green : .secondary)
                }
            }
        }

        // 4. 8 线程极速下载权重直达 ComfyUI 云盘目录
        WorkspaceCard(
            title: L("8 线程极速下载权重至 ComfyUI 云盘目录", "8-Thread High-Speed Weight Downloader to ComfyUI Drive"),
            subtitle: L(
                "比浏览器单线程快 5~10 倍，下载完成后自动软链落盘至 Google Drive；在 ComfyUI 画布按 R 键即可刷新选用",
                "5–10× faster than single-thread browser downloads, persisted to Google Drive via symlinks; press R in ComfyUI to refresh node dropdowns"
            ),
            icon: "arrow.down.circle.dotted"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("目标模型目录 (ComfyUI/models/...)", "Target Subfolder (ComfyUI/models/...)"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker(L("目标目录", "Target Folder"), selection: $vm.comfyWeightSubfolder) {
                            ForEach(modelSubfolders, id: \.0) { item in
                                Text(item.1).tag(item.0)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 285)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("HuggingFace 直链 / 下载 URL / 仓库 ID", "HuggingFace Direct URL / Download Link / Repo ID"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField(
                            L("URL 或 org/repo", "URL or org/repo"),
                            text: $vm.comfyWeightSourceInput,
                            prompt: Text(L(
                                "如 https://huggingface.co/.../resolve/main/xxx.safetensors",
                                "e.g. https://huggingface.co/.../resolve/main/xxx.safetensors"
                            ))
                        )
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                    }
                }

                HStack(spacing: 10) {
                    TextField(
                        L("可选文件名或仓库内子路径", "Optional filename or repo subpath"),
                        text: $vm.comfyWeightFilenameInput,
                        prompt: Text(L(
                            "直链可留空；填仓库 ID 时填仓库内文件路径（如 split_files/vae/xxx.safetensors）",
                            "Leave blank for direct URLs; when entering a Repo ID, specify subpath (e.g. split_files/vae/xxx.safetensors)"
                        ))
                    )
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))

                    Button {
                        Task { await vm.startComfyWeightDownload() }
                    } label: {
                        HStack(spacing: 5) {
                            if vm.comfyDownloadingWeight {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "bolt.horizontal.fill")
                            }
                            Text(vm.comfyDownloadingWeight
                                 ? L("极速下载中...", "Downloading...")
                                 : L("8 线程下载至云盘", "8-Thread Download to Drive"))
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!vm.isConnected || vm.comfyDownloadingWeight)
                }
            }
        }

        // 5. ComfyUI 云端输出成片库 + 本地预览联动
        HStack(alignment: .top, spacing: 14) {
            mediaPreviewCard

            WorkspaceCard(
                title: L("ComfyUI 输出成片", "ComfyUI Cloud Outputs"),
                subtitle: L("点击一键拉取至 Mac 本地", "Click to pull renders to local Mac"),
                icon: "film.stack"
            ) {
                if vm.comfyRecentOutputs.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 22))
                            .foregroundStyle(.secondary.opacity(0.6))
                        Text(L(
                            "在 ComfyUI 画布渲染生成的视频与图片会自动显示在此处，并同步保存至 Google Drive",
                            "Videos and images rendered in the ComfyUI canvas appear here automatically and sync to Google Drive"
                        ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                } else {
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(vm.comfyRecentOutputs) { item in
                                HStack(spacing: 8) {
                                    Image(systemName: item.media_type == "video" ? "film" : "photo")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color.accentColor)
                                        .frame(width: 20)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.filename)
                                            .font(.system(size: 11.5, weight: .medium))
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        Text("\(fmt(item.size_mb ?? 0, 1)) MB · \(item.media_type == "video" ? L("视频", "Video") : L("图像", "Image"))")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 4)
                                    Button {
                                        Task { await vm.downloadComfyOutputToMac(item) }
                                    } label: {
                                        if vm.comfyPullingOutputRelPath == item.rel_path {
                                            ProgressView().controlSize(.mini)
                                        } else {
                                            Image(systemName: "arrow.down.to.line.compact")
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .disabled(vm.comfyPullingOutputRelPath != nil)
                                    .help(L("拉取到 Mac 本地目录并在左侧播放器预览", "Pull to local Mac folder & preview in player"))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 7).fill(palette.inputFill))
                            }
                        }
                    }
                    .frame(maxHeight: 280)
                }
            }
            .frame(width: 290)
        }
    }

    private func comfyPersistMetricTile(
        title: String,
        value: String,
        detail: String,
        icon: String,
        palette: StudioPalette
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text(title)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(detail)
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 9).fill(palette.inputFill))
        .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(palette.cardBorder, lineWidth: 0.7))
    }

    private func comfyStepChip(
        num: String,
        title: String,
        icon: String,
        palette: StudioPalette
    ) -> some View {
        HStack(spacing: 6) {
            Text(num)
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(Color.accentColor))
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(palette.inputFill))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(palette.cardBorder, lineWidth: 0.7))
    }

    private func comfyPresetPackRow(_ pack: ComfyPresetPackItem, palette: StudioPalette) -> some View {
        let isInstallingThis = vm.comfyInstallingPackId == pack.id
        let isAnyBusy = vm.comfyDownloadingWeight || !vm.comfyInstallingPackId.isEmpty || vm.comfyStarting
        let isPrimaryRecommended = pack.id == "wan22_i2v_flf2v"

        return VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(pack.ready ? Color.green.opacity(0.14) : Color.accentColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: pack.ready ? "checkmark.seal.fill" : (pack.id.contains("minimax") || pack.id.contains("ltx") ? "waveform.and.magnifyingglass" : "film.stack.fill"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(pack.ready ? Color.green : Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Text(pack.localizedTitle)
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundStyle(.primary)

                        Text(pack.localizedBadge)
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(isPrimaryRecommended ? Color.white : Color.accentColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(isPrimaryRecommended ? Color.accentColor : Color.accentColor.opacity(0.13))
                            )

                        if pack.ready {
                            Text(L("已配齐就绪", "Ready"))
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundStyle(Color.green)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.green.opacity(0.13)))
                        }
                    }

                    Text(pack.localizedScenario)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Label(
                            L("权重 \(pack.installed_models)/\(pack.total_models) · 约 \(fmt(pack.approx_size_gb, 1)) GB",
                              "Weights \(pack.installed_models)/\(pack.total_models) · ~\(fmt(pack.approx_size_gb, 1)) GB"),
                            systemImage: "internaldrive"
                        )
                            .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)

                        Text("·")
                            .foregroundStyle(.secondary)

                        ForEach(pack.workflows, id: \.self) { wfName in
                            Text(ComfyPresetPackItem.localizedWorkflowLabel(wfName))
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundStyle(.primary.opacity(0.85))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.06)))
                                .lineLimit(1)
                        }
                    }
                    .padding(.top, 1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 6) {
                    if pack.ready {
                        HStack(spacing: 6) {
                            Button {
                                Task { await vm.installComfyPresetPack(pack, openWhenReady: false) }
                            } label: {
                                Text(L("重写中文模板", "Rebuild Templates"))
                                    .font(.system(size: 11.5))
                            }
                            .controlSize(.small)
                            .disabled(!vm.isConnected || isAnyBusy)
                            .help(L(
                                "重新生成该工作流包的标准中文傻瓜注释画布文件",
                                "Regenerate annotated workflow JSON templates for this pack"
                            ))

                            Button {
                                if vm.comfyRunning && !vm.comfyPublicURL.isEmpty {
                                    vm.openComfyUIInBrowser()
                                } else {
                                    Task { await vm.startRemoteComfyUI(forceRestart: false, autoOpenBrowser: true) }
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "safari.fill")
                                    Text(L("打开画布直接使用", "Open in Canvas"))
                                        .fontWeight(.semibold)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .disabled(!vm.isConnected || isAnyBusy)
                        }
                    } else {
                        Button {
                            Task { await vm.installComfyPresetPack(pack, openWhenReady: true) }
                        } label: {
                            HStack(spacing: 6) {
                                if isInstallingThis {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "bolt.badge.checkmark.fill")
                                }
                                Text(isInstallingThis
                                     ? L("正在极速配齐 (\(Int((vm.comfyProgress * 100).rounded()))%)...",
                                         "Installing (\(Int((vm.comfyProgress * 100).rounded()))%)...")
                                     : L("一键配齐模型与工作流", "1-Click Install Pack"))
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!vm.isConnected || isAnyBusy)
                    }
                }
            }

            if isInstallingThis {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: vm.comfyProgress, total: 1.0)
                    Text(vm.displayComfyStatusMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.accentColor)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isPrimaryRecommended && !pack.ready
                      ? Color.accentColor.opacity(colorScheme == .dark ? 0.10 : 0.045)
                      : palette.inputFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    pack.ready ? Color.green.opacity(0.45) : (isPrimaryRecommended ? Color.accentColor.opacity(0.45) : palette.cardBorder),
                    lineWidth: (isPrimaryRecommended || pack.ready) ? 1.1 : 0.7
                )
        )
    }

    // MARK: - OpenAI & Anthropic 双协议公网 API 服务网关面板

    private func copyToPasteboard(_ text: String, tip: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        vm.statusMessage = tip
    }

    private func apiGatewaySection(palette: StudioPalette) -> some View {
        let baseHost = vm.normalizedBaseURL.isEmpty ? "https://xxxx.gradio.live" : vm.normalizedBaseURL
        let openaiBase = "\(baseHost)/v1"
        let anthropicBase = baseHost
        let displayKey = vm.apiKeyEnabled ? vm.apiAccessKey : "sk-no-key-required"
        let activeLLMRepo: String = {
            if vm.activeModelSpec.modality == .llmVLM { return vm.activeModelSpec.repoId }
            if let loadedLLM = OPEN_MODEL_CATALOG.first(where: {
                $0.modality == .llmVLM && vm.loadedModelIds.contains($0.id)
            }) {
                return loadedLLM.repoId
            }
            return "Qwen/Qwen3.8-27B"
        }()
        let activeLLMDisplayName = String(activeLLMRepo.split(separator: "/").last ?? "")

        let samplePrompt1 = L("用三句话解释量子纠缠，并展示思考过程", "Explain quantum entanglement in 3 sentences with reasoning")
        let samplePrompt2 = L("帮我设计一个高并发网关架构", "Design a high-concurrency API gateway architecture")
        let samplePrompt3 = L("分析 Rust 所有权机制的核心优势", "Analyze the core advantages of Rust's ownership model")

        let openaiCurl = """
        curl \(openaiBase)/chat/completions \\
          -H "Content-Type: application/json" \\
          -H "Authorization: Bearer \(displayKey)" \\
          -d '{
            "model": "\(activeLLMRepo)",
            "stream": true,
            "messages": [{"role": "user", "content": "\(samplePrompt1)"}]
          }'
        """

        let openaiPython = """
        from openai import OpenAI

        client = OpenAI(base_url="\(openaiBase)", api_key="\(displayKey)")
        stream = client.chat.completions.create(
            model="\(activeLLMRepo)",
            messages=[{"role": "user", "content": "\(samplePrompt2)"}],
            stream=True,
        )
        for chunk in stream:
            delta = chunk.choices[0].delta
            if getattr(delta, "reasoning_content", None):
                print(delta.reasoning_content, end="", flush=True)
            if delta.content:
                print(delta.content, end="", flush=True)
        """

        let cursorConfig = """
        # \(L("Cursor -> Settings -> Models -> OpenAI API Key 配置", "Cursor -> Settings -> Models -> OpenAI API Key"))
        Override OpenAI Base URL: \(openaiBase)
        OpenAI API Key:           \(displayKey)
        Custom Model Name:        \(activeLLMRepo)
        """

        let anthropicCurl = """
        curl \(anthropicBase)/v1/messages \\
          -H "Content-Type: application/json" \\
          -H "x-api-key: \(displayKey)" \\
          -H "anthropic-version: 2023-06-01" \\
          -d '{
            "model": "\(activeLLMRepo)",
            "max_tokens": 2048,
            "stream": true,
            "messages": [{"role": "user", "content": "\(samplePrompt3)"}]
          }'
        """

        let claudeCodeEnv = """
        export ANTHROPIC_BASE_URL="\(anthropicBase)"
        export ANTHROPIC_API_KEY="\(displayKey)"
        export ANTHROPIC_MODEL="\(activeLLMRepo)"
        """

        return VStack(alignment: .leading, spacing: 16) {
            WorkspaceCard(
                title: L("网关安全鉴权与运行状态", "Gateway Authentication & Status"),
                subtitle: L(
                    "公网隧道开启期间，建议保持密钥鉴权开启以保护你的 Colab 算力单元 (CU)",
                    "Keep API Key authentication enabled while the public tunnel is live to protect your Colab Compute Units (CU)"
                ),
                icon: "lock.shield",
                trailing: AnyView(
                    Text(L("累计 API 请求: \(vm.apiRequestCount) 次", "Total API Requests: \(vm.apiRequestCount)"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                )
            ) {
                HStack(spacing: 12) {
                    Toggle(
                        L("启用 API Key 鉴权（同时校验 Bearer 与 x-api-key）",
                          "Require API Key Auth (validates both Bearer & x-api-key)"),
                        isOn: $vm.apiKeyEnabled
                    )
                        .font(.callout.weight(.medium))

                    Spacer()

                    if !vm.isQwenLoadedInVRAM {
                        Text(L(
                            "提示：请先在左侧点击「加载到显存」装载 \(activeLLMDisplayName)（可与其他模型同时共驻显存）",
                            "Tip: Click 'Load to VRAM' on the left to load \(activeLLMDisplayName) first (co-resides with other models)"
                        ))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else if vm.loadedModelIds.count > 1 {
                        Text(L(
                            "多模型共驻已激活：外部 API 可随时调用 \(activeLLMDisplayName)，与视频/生图模型零切换共存",
                            "Multi-model VRAM active: external clients can call \(activeLLMDisplayName) alongside video/image models with zero reload"
                        ))
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                if vm.apiKeyEnabled {
                    HStack(spacing: 8) {
                        Text(L("访问密钥", "API Key"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("API Key", text: $vm.apiAccessKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                            .onSubmit {
                                Task { await vm.syncApiKeyToColab() }
                            }
                        Button(L("同步到云端", "Sync to Cloud")) {
                            Task {
                                await vm.syncApiKeyToColab()
                                vm.statusMessage = L("API 密钥已同步更新至 Colab 云端网关。", "API Key synced to Colab cloud gateway.")
                            }
                        }
                        .controlSize(.small)
                        .disabled(!vm.isConnected)

                        Button(L("重新生成", "Regenerate")) {
                            vm.regenerateApiKey()
                            vm.statusMessage = L("已生成新的随机 API Key。", "Generated a new random API Key.")
                        }
                        .controlSize(.small)

                        Button(L("复制密钥", "Copy Key")) {
                            copyToPasteboard(vm.apiAccessKey, tip: L("已复制 API Key 到剪贴板。", "Copied API Key to clipboard."))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }

            HStack(alignment: .top, spacing: 16) {
                // OpenAI 协议卡片
                WorkspaceCard(
                    title: L("OpenAI 兼容协议", "OpenAI-Compatible Protocol (`/v1`)"),
                    subtitle: L(
                        "兼容 OpenAI SDK、Cursor、Cherry Studio、Chatbox 等客户端",
                        "Compatible with OpenAI SDK, Cursor, Cherry Studio, Chatbox & more"
                    ),
                    icon: "bolt.horizontal.circle"
                ) {
                    endpointRow(label: "Base URL", value: openaiBase, tip: L("已复制 OpenAI Base URL", "Copied OpenAI Base URL"))
                    endpointRow(label: L("Chat 接口", "Chat URL"), value: "\(openaiBase)/chat/completions", tip: L("已复制 Chat Completions 地址", "Copied Chat Completions URL"))
                    endpointRow(label: L("模型名称", "Model ID"), value: activeLLMRepo, tip: L("已复制模型名称", "Copied Model ID"))

                    Text(L(
                        "支持 stream 流式输出、reasoning_content 深度思考链、image_url 视觉输入与 Function Calling 工具调用；加载图像模型时亦支持 /v1/images/generations。",
                        "Supports SSE streaming, `reasoning_content` thinking chains, `image_url` vision inputs, and Function Calling; also serves `/v1/images/generations` when an image model is loaded."
                    ))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("", selection: $openaiSnippetTab) {
                        Text(L("Python 示例", "Python SDK")).tag(0)
                        Text("Cursor").tag(1)
                        Text("curl").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .controlSize(.small)

                    codeSnippetBlock(
                        title: openaiSnippetTab == 0
                            ? L("Python OpenAI SDK 流式示例", "Python OpenAI SDK Streaming Example")
                            : (openaiSnippetTab == 1 ? L("Cursor 编辑器接入配置", "Cursor IDE Custom Model Setup") : "OpenAI Chat Completions curl"),
                        code: openaiSnippetTab == 0 ? openaiPython : (openaiSnippetTab == 1 ? cursorConfig : openaiCurl),
                        palette: palette
                    )

                    HStack(spacing: 8) {
                        Button(L("复制 Python 代码", "Copy Python")) {
                            copyToPasteboard(openaiPython, tip: L("已复制 OpenAI Python 调用代码。", "Copied OpenAI Python snippet."))
                        }
                        .controlSize(.small)

                        Button(L("复制 Cursor 配置", "Copy Cursor")) {
                            copyToPasteboard(cursorConfig, tip: L("已复制 Cursor 接入配置。", "Copied Cursor configuration."))
                        }
                        .controlSize(.small)

                        Button(L("复制 curl 命令", "Copy curl")) {
                            copyToPasteboard(openaiCurl, tip: L("已复制 OpenAI curl 测试命令。", "Copied OpenAI curl command."))
                        }
                        .controlSize(.small)
                    }
                }

                // Anthropic 协议卡片
                WorkspaceCard(
                    title: L("Anthropic Messages 协议", "Anthropic Messages Protocol (`/v1/messages`)"),
                    subtitle: L(
                        "原生实现 /v1/messages，兼容 Anthropic SDK 与 Claude Code",
                        "Native `/v1/messages` endpoint for Anthropic SDK & Claude Code"
                    ),
                    icon: "chevron.left.forwardslash.chevron.right"
                ) {
                    endpointRow(label: "Base URL", value: anthropicBase, tip: L("已复制 Anthropic Base URL", "Copied Anthropic Base URL"))
                    endpointRow(label: "Messages", value: "\(anthropicBase)/v1/messages", tip: L("已复制 Anthropic Messages 地址", "Copied Anthropic Messages URL"))
                    endpointRow(label: L("鉴权请求头", "Auth Header"), value: L("x-api-key 或 Authorization: Bearer", "x-api-key or Authorization: Bearer"), tip: L("已复制请求头说明", "Copied auth header format"))

                    Text(L(
                        "完整支持 Anthropic SSE 事件流（thinking_delta 思考块、text_delta 文本块、tool_use 工具块）及 /v1/messages/count_tokens 接口，任意模型名均可自动路由至 \(activeLLMDisplayName)。",
                        "Full Anthropic SSE streaming (`thinking_delta`, `text_delta`, `tool_use`) plus `/v1/messages/count_tokens`; any model alias routes automatically to \(activeLLMDisplayName)."
                    ))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("", selection: $anthropicSnippetTab) {
                        Text("Claude Code").tag(0)
                        Text("curl").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .controlSize(.small)

                    codeSnippetBlock(
                        title: anthropicSnippetTab == 0
                            ? L("Claude Code / 终端环境变量接入", "Claude Code / Shell Environment Variables")
                            : "Anthropic /v1/messages curl",
                        code: anthropicSnippetTab == 0 ? claudeCodeEnv : anthropicCurl,
                        palette: palette
                    )

                    HStack(spacing: 8) {
                        Button(L("复制环境变量配置", "Copy Claude Code Env")) {
                            copyToPasteboard(claudeCodeEnv, tip: L("已复制 ANTHROPIC_BASE_URL 环境变量配置。", "Copied ANTHROPIC_BASE_URL environment variables."))
                        }
                        .controlSize(.small)

                        Button(L("复制 Anthropic curl", "Copy Anthropic curl")) {
                            copyToPasteboard(anthropicCurl, tip: L("已复制 Anthropic /v1/messages curl 命令。", "Copied Anthropic /v1/messages curl command."))
                        }
                        .controlSize(.small)
                    }
                }
            }
        }
    }

    private func endpointRow(label: String, value: String, tip: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(.system(size: 11.5, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(L("复制", "Copy")) {
                copyToPasteboard(value, tip: tip)
            }
            .controlSize(.mini)
        }
        .padding(.vertical, 2)
    }

    private func codeSnippetBlock(title: String, code: String, palette: StudioPalette) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal) {
                Text(code)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color(white: 0.88))
                    .textSelection(.enabled)
                    .padding(10)
            }
            .environment(\.colorScheme, .dark)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 122)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.08, green: 0.09, blue: 0.11)))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - 优化后的醒目模式切换器 (Mode Switcher Bar)

    private func modeSwitcherHeader(palette: StudioPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: vm.activeModelSpec.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32, height: 32)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.accentColor.opacity(0.12)))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(vm.activeModelSpec.name)
                            .font(.title3.weight(.bold))
                        Text(vm.activeModelSpec.repoId)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.primary.opacity(0.06)))
                    }
                    Text(vm.activeModelSpec.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    if vm.loadedModelIds.count > 1 {
                        HStack(spacing: 4) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 10, weight: .semibold))
                            Text(L("\(vm.loadedModelIds.count) 模型显存共驻", "\(vm.loadedModelIds.count) Models in VRAM"))
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                    }

                    HStack(spacing: 6) {
                        StatusDot(color: vm.isSelectedModelLoadedInVRAM ? .green : .secondary.opacity(0.5))
                        Text(vm.isSelectedModelLoadedInVRAM
                             ? L("显存已就绪", "Ready in VRAM")
                             : L("待加载至显存", "Not Loaded in VRAM"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(vm.isSelectedModelLoadedInVRAM ? Color.green : Color.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(palette.inputFill))
                    .overlay(Capsule().strokeBorder(palette.cardBorder, lineWidth: 0.8))
                }
            }

            // 双卡片式高辨识度模式切换栏
            HStack(spacing: 12) {
                ForEach(vm.activeModelSpec.modes) { mode in
                    let isSelected = vm.taskModeId == mode.id
                    Button {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                            vm.taskModeId = mode.id
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.06))
                                    .frame(width: 38, height: 38)
                                Image(systemName: mode.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(isSelected ? Color.white : Color.secondary)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(mode.title)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                                    if isSelected {
                                        Text(L("当前模式", "Active"))
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(Color.accentColor)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 1.5)
                                            .background(Capsule().fill(Color.accentColor.opacity(0.14)))
                                    }
                                }
                                Text(mode.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.45))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? Color.accentColor.opacity(colorScheme == .dark ? 0.16 : 0.07) : palette.inputFill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    isSelected ? Color.accentColor : palette.cardBorder,
                                    lineWidth: isSelected ? 1.6 : 0.8
                                )
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(palette.workspaceCardFill)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.04), radius: 4, x: 0, y: 1.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(palette.cardBorder, lineWidth: 0.8)
        )
    }

    @ViewBuilder
    private var referenceImageSection: some View {
        switch vm.taskModeId {
        case "fl2va":
            WorkspaceCard(
                title: L("首尾关键帧参考图", "Start & End Keyframe Images"),
                subtitle: L("至少拖入首帧或尾帧之一，精准锁定起止画面构图", "Drop at least a start frame or end frame to anchor camera motion & composition"),
                icon: "photo.on.rectangle.angled"
            ) {
                HStack(spacing: 12) {
                    FrameDropWell(
                        title: L("起始首帧 (Index 0)", "Start Frame (Index 0)"),
                        subtitle: L("拖入图片或点击选择", "Drop an image or click to browse"),
                        image: $vm.firstFrameImage
                    )
                    FrameDropWell(
                        title: L("结束尾帧 (可选 · Index -1)", "End Frame (Optional · Index -1)"),
                        subtitle: L("拖入图片或点击选择", "Drop an image or click to browse"),
                        image: $vm.lastFrameImage
                    )
                }
            }
        case "i2v":
            WorkspaceCard(
                title: L("起始首帧参考图", "Start Keyframe Image"),
                subtitle: L("模型将以该图片作为视频第 1 帧向后延展动态画面", "The model animates forward starting from this image as frame 0"),
                icon: "photo.badge.arrow.down"
            ) {
                FrameDropWell(
                    title: L("首帧原图", "Start Frame Image"),
                    subtitle: L("拖入本地图片或点击浏览", "Drop a local image or click to browse"),
                    image: $vm.firstFrameImage
                )
            }
        case "i2i_edit":
            WorkspaceCard(
                title: vm.selectedModelId == "qwen_image_21"
                    ? L("指令修图参考原图", "Instruction Image-Editing References")
                    : L("图生图重绘参考底图", "Image-to-Image Reference"),
                subtitle: vm.selectedModelId == "qwen_image_21"
                    ? L("支持上传 1~2 张参考图进行局部编辑、换背景或多主体融合", "Upload 1–2 reference images for local edits, background swaps, or multi-subject fusion")
                    : L("上传参考原图并在左侧调节重绘幅度", "Upload a reference image and tune Denoising Strength in the left sidebar"),
                icon: "wand.and.rays"
            ) {
                HStack(spacing: 12) {
                    FrameDropWell(
                        title: L("主参考图 1 (必选)", "Primary Reference 1 (Required)"),
                        subtitle: L("拖入待编辑原图", "Drop source image to edit"),
                        image: $vm.firstFrameImage
                    )
                    if vm.selectedModelId == "qwen_image_21" {
                        FrameDropWell(
                            title: L("融合参考图 2 (可选)", "Fusion Reference 2 (Optional)"),
                            subtitle: L("用于多图主体融合编辑", "For multi-image subject fusion"),
                            image: $vm.lastFrameImage
                        )
                    }
                }
            }
        case "vlm":
            WorkspaceCard(
                title: L("待分析视觉图像", "Vision Reference Images"),
                subtitle: L(
                    "支持拖入 1~2 张截图、摄影或分镜画稿交由 \(vm.activeModelSpec.name) 解析",
                    "Drop 1–2 screenshots, photos, or storyboard sketches for \(vm.activeModelSpec.name) to analyze"
                ),
                icon: "eye"
            ) {
                HStack(spacing: 12) {
                    FrameDropWell(
                        title: L("输入图像 1", "Input Image 1"),
                        subtitle: L("拖入图片进行解析或反推提示词", "Drop an image to analyze or reverse-engineer prompts"),
                        image: $vm.firstFrameImage
                    )
                    FrameDropWell(
                        title: L("对比图像 2 (可选)", "Comparison Image 2 (Optional)"),
                        subtitle: L("可同时传入第二张图像对比分析", "Optionally attach a second image for side-by-side comparison"),
                        image: $vm.lastFrameImage
                    )
                }
            }
        default:
            EmptyView()
        }
    }

    private func promptComposerSection(palette: StudioPalette) -> some View {
        let mod = vm.activeModelSpec.modality
        let cardTitle: String = {
            switch mod {
            case .llmVLM:
                return L("问题与指令输入", "Message & Instruction Input")
            case .image:
                return vm.taskModeId == "i2i_edit"
                    ? L("修图指令与画面描述", "Editing Instruction & Scene Prompt")
                    : L("图像画面提示词", "Image Prompt")
            case .videoAudio, .video, .comfyUI:
                return L("镜头与多模态提示词", "Camera & Multimodal Prompts")
            }
        }()

        let primaryPlaceholder: String = {
            switch mod {
            case .llmVLM:
                return L("输入你想提问、推理编码或反推提示词的内容...", "Enter a question, coding task, or vision prompt...")
            case .image:
                return vm.taskModeId == "i2i_edit"
                    ? L("描述你想修改的细节（例如：把背景换成夕阳海滩，保留人物光影）...", "Describe your edit (e.g. replace background with a sunset beach while preserving lighting)...")
                    : L("描述主体、构图、镜头景别、光影色调与文字排版...", "Describe subject, composition, lighting, lens style, and typography...")
            case .videoAudio, .video, .comfyUI:
                return L("描述画面主体运动、镜头推拉摇移、光影氛围与电影质感...", "Describe subject motion, camera movement, lighting, and cinematic style...")
            }
        }()

        return WorkspaceCard(title: cardTitle, icon: "text.alignleft") {
            promptEditor(
                title: mod == .llmVLM
                    ? L("对话内容 / 视觉提问", "Chat Message / Vision Question")
                    : (vm.taskModeId == "i2i_edit"
                       ? L("编辑指令或目标画面描述", "Edit Instruction or Target Scene")
                       : L("主体、构图、光影与风格描述", "Subject, Composition, Lighting & Style")),
                placeholder: primaryPlaceholder,
                text: $vm.visualPrompt,
                height: mod == .llmVLM ? 84 : 92,
                palette: palette
            )

            if mod == .videoAudio {
                HStack(alignment: .top, spacing: 12) {
                    promptEditor(
                        title: L("环境音效与台词对白（可选）", "Soundscape, Foley & Dialogue (Optional)"),
                        placeholder: L("如：海浪拍岸声、脚步声、角色轻声说台词...", "e.g. Ocean waves crashing, footsteps on gravel, spoken dialogue..."),
                        text: $vm.soundscapePrompt,
                        height: 58,
                        palette: palette
                    )
                    promptEditor(
                        title: L("背景音乐风格（可选）", "Background Music Style (Optional)"),
                        placeholder: L("如：温暖大提琴与原声吉他电影配乐...", "e.g. Warm cinematic cello and acoustic guitar score..."),
                        text: $vm.musicPrompt,
                        height: 58,
                        palette: palette
                    )
                }

                DisclosureGroup(
                    L("反向提示词 Negative Prompt（可选，排除低质或多余元素）", "Negative Prompt (Optional — exclude artifacts or unwanted elements)"),
                    isExpanded: $showNegativePrompt
                ) {
                    promptEditor(
                        title: L("反向排除项", "Negative Terms"),
                        placeholder: L("如：模糊、畸变、水印、多余肢体、画面闪烁...", "e.g. blurry, distorted, watermark, extra limbs, flickering..."),
                        text: $vm.negativePrompt,
                        height: 44,
                        palette: palette
                    )
                    .padding(.top, 4)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            } else if mod == .image || mod == .video {
                promptEditor(
                    title: L("反向提示词 Negative Prompt（可选，排除低质或多余元素）", "Negative Prompt (Optional — exclude low quality or unwanted elements)"),
                    placeholder: L("如：模糊、低分辨率、畸变、水印、杂乱文字...", "e.g. blurry, low resolution, deformed, watermark, garbled text..."),
                    text: $vm.negativePrompt,
                    height: 46,
                    palette: palette
                )
            }
        }
    }

    private func promptEditor(
        title: String,
        placeholder: String = "",
        text: Binding<String>,
        height: CGFloat,
        palette: StudioPalette
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty && !placeholder.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(.secondary.opacity(0.55))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
                TextEditor(text: text)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
            .frame(height: height)
            .background(RoundedRectangle(cornerRadius: 8).fill(palette.inputFill))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(palette.cardBorder, lineWidth: 0.8))
        }
        .frame(maxWidth: .infinity)
    }

    private var generateButtonTitle: String {
        let mod = vm.activeModelSpec.modality
        if vm.isGenerating {
            let liveTime = vm.currentJobElapsed > 0.05
                ? L(" · 已耗时 \(formatDuration(vm.currentJobElapsed, compact: true))",
                    " · \(formatDuration(vm.currentJobElapsed, compact: true))")
                : ""
            if mod == .llmVLM {
                return L(
                    "\(vm.activeModelSpec.name) 正在推理输出\(liveTime)...",
                    "\(vm.activeModelSpec.name) generating\(liveTime)..."
                )
            }
            return vm.batchCount > 1
                ? L("正在生成（共 \(vm.batchCount) 项\(liveTime)）...",
                    "Generating (\(vm.batchCount) items\(liveTime))...")
                : L("正在云端 GPU 生成\(liveTime)...",
                    "Generating on Cloud GPU\(liveTime)...")
        }
        if !vm.isSelectedModelLoadedInVRAM {
            return L(
                "开始运行（请先在左侧将 \(vm.activeModelSpec.name) 加载到显存）",
                "Run (Load \(vm.activeModelSpec.name) to VRAM on the left first)"
            )
        }
        switch mod {
        case .llmVLM:
            return L("发送并开始深度推理 (Command + Return)", "Send & Start Reasoning (Command + Return)")
        case .image:
            return vm.batchCount > 1
                ? L("生成 \(vm.batchCount) 张高清图像", "Generate \(vm.batchCount) HD Images")
                : L("开始生成图像", "Generate Image")
        case .videoAudio:
            return vm.batchCount > 1
                ? L("连续生成 \(vm.batchCount) 条全模态音视频", "Generate \(vm.batchCount) Videos with Audio")
                : L("开始生成音视频", "Generate Video + Audio")
        case .video, .comfyUI:
            return vm.batchCount > 1
                ? L("连续生成 \(vm.batchCount) 条高清视频", "Generate \(vm.batchCount) HD Videos")
                : L("开始生成视频", "Generate Video")
        }
    }

    private var generateActionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    Task { await vm.startGeneration() }
                } label: {
                    HStack(spacing: 8) {
                        if vm.isGenerating {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: vm.activeModelSpec.modality == .llmVLM ? "paperplane.fill" : "play.fill")
                        }
                        Text(generateButtonTitle)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(vm.isGenerating)
                .keyboardShortcut(.return, modifiers: [.command])

                if vm.isGenerating {
                    Button(role: .destructive) {
                        Task { await vm.cancelCurrentGeneration() }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "stop.fill")
                                .font(.caption)
                            Text(L("停止推理", "Stop"))
                                .font(.headline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .help(L("立即中断当前云端推理任务并解锁操作", "Abort the running cloud GPU job immediately"))
                }
            }

            if vm.isGenerating {
                HStack(spacing: 8) {
                    ProgressView(value: vm.progressValue, total: 1.0)
                    Text("\(Int((vm.progressValue * 100).rounded()))%")
                        .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 38, alignment: .trailing)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(vm.displayStatusMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }

    // MARK: - Qwen3.8-27B / GGUF 专属流式思考与多轮对话面板

    private func llmConversationCard(palette: StudioPalette) -> some View {
        WorkspaceCard(
            title: L(
                "\(vm.activeModelSpec.name) 深度推理与视觉对话输出",
                "\(vm.activeModelSpec.name) Deep Reasoning & Vision Chat"
            ),
            subtitle: L(
                "实时流式展示模型内部思考链与最终回答（当前上下文窗口 \(vm.contextLengthK)K），支持一键复制为视频/生图提示词",
                "Streams internal chain-of-thought and final response in real time (\(vm.contextLengthK)K context window)"
            ),
            icon: "bubble.left.and.text.bubble.right",
            trailing: AnyView(
                HStack(spacing: 8) {
                    Button {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                            vm.taskModeId = "api"
                        }
                    } label: {
                        Label(L("API 接入配置", "API Gateway"), systemImage: "network")
                    }
                    .controlSize(.small)

                    Button(L("清空对话", "Clear Chat")) {
                        vm.chatHistory.removeAll()
                    }
                    .controlSize(.small)
                    .disabled(vm.chatHistory.isEmpty || vm.isGenerating)
                }
            )
        ) {
            if vm.chatHistory.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "brain")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary.opacity(0.6))
                    Text(L(
                        "加载 \(vm.activeModelSpec.name) 后，在上方输入问题或拖入图片即可开启流式深度推理",
                        "Load \(vm.activeModelSpec.name), then enter a prompt or drop images above to stream reasoning & answers"
                    ))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 240)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(vm.chatHistory) { turn in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: turn.role == "user" ? "person.fill" : "sparkles")
                                    .font(.caption)
                                    .foregroundStyle(turn.role == "user" ? Color.secondary : Color.accentColor)
                                Text(turn.role == "user" ? L("提问", "You") : vm.activeModelSpec.name)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(turn.role == "user" ? Color.secondary : Color.accentColor)
                                if turn.hasImage {
                                    Text(L("附带视觉图像", "Image Attached"))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1)
                                        .background(Capsule().fill(Color.primary.opacity(0.06)))
                                }
                                Spacer()
                                if turn.role == "assistant" && !turn.content.isEmpty {
                                    Button(L("复制回复", "Copy Reply")) {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(turn.content, forType: .string)
                                    }
                                    .controlSize(.mini)
                                }
                            }

                            if !turn.thinking.isEmpty {
                                DisclosureGroup(L(
                                    "深度思考过程 (\(turn.thinking.count) 字)",
                                    "Chain of Thought (\(turn.thinking.count) chars)"
                                )) {
                                    Text(turn.thinking)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 4)
                                }
                                .font(.caption.weight(.medium))
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
                            }

                            if !turn.content.isEmpty {
                                Text(turn.content)
                                    .font(.body)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else if turn.role == "assistant" && vm.isGenerating {
                                HStack(spacing: 6) {
                                    ProgressView().controlSize(.small)
                                    Text(L("正在思考并组织回答...", "Thinking and composing response..."))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(turn.role == "user" ? palette.inputFill : palette.workspaceCardFill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .strokeBorder(palette.cardBorder, lineWidth: 0.7)
                        )
                    }
                }
            }
        }
    }

    // MARK: - 多媒体预览与历史面板（兼容视频播放与高清图像展示）

    private var mediaPreviewCard: some View {
        let curElapsed = vm.elapsedForMedia(vm.currentMediaURL)
        return WorkspaceCard(
            title: L("生成结果预览", "Output Preview"),
            icon: "play.rectangle",
            trailing: curElapsed != nil ? AnyView(
                HStack(spacing: 4) {
                    Image(systemName: "stopwatch.fill")
                        .font(.system(size: 10.5, weight: .semibold))
                    Text(L("生成耗时 \(formatDuration(curElapsed!))", "Elapsed \(formatDuration(curElapsed!))"))
                        .font(.system(size: 11, weight: .semibold))
                        .monospacedDigit()
                }
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(Capsule().fill(Color.accentColor.opacity(0.12)))
            ) : nil
        ) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color(red: 0.06, green: 0.065, blue: 0.08))

                if let img = vm.currentPreviewImage {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(6)
                } else if let player = vm.player {
                    VideoPlayer(player: player)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: vm.activeModelSpec.modality == .image ? "photo" : "film")
                            .font(.system(size: 32))
                            .foregroundStyle(.gray)
                        Text(L(
                            "生成的视频或高清图像将自动下载并在此预览",
                            "Generated videos or HD images will download automatically and preview here"
                        ))
                            .font(.callout)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .frame(minHeight: 330)

            if let url = vm.currentMediaURL {
                HStack(spacing: 8) {
                    Image(systemName: vm.currentPreviewImage != nil ? "photo" : "film")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(url.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if let el = curElapsed {
                        Text(formatDuration(el, compact: true))
                            .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(Color.primary.opacity(0.06)))
                    }
                    Spacer()
                    if vm.player != nil {
                        Button(L("重播", "Replay")) {
                            vm.player?.seek(to: .zero)
                            vm.player?.play()
                        }
                        .controlSize(.small)
                    } else {
                        Button(L("用预览打开", "Open")) {
                            NSWorkspace.shared.open(url)
                        }
                        .controlSize(.small)
                    }
                    Button(L("在 Finder 中显示", "Show in Finder")) {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                    .controlSize(.small)
                }
            }
        }
    }

    private var mediaHistoryCard: some View {
        let displayLocale = Locale(identifier: i18n.isEN ? "en_US" : "zh_CN")
        return WorkspaceCard(
            title: L("本地历史", "Local History"),
            subtitle: L("\(vm.localMediaItems.count) 个媒体文件", "\(vm.localMediaItems.count) media files"),
            icon: "clock.arrow.circlepath",
            trailing: AnyView(
                Button {
                    vm.refreshLocalMedia()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help(L("刷新本地列表", "Refresh local media list"))
            )
        ) {
            if vm.localMediaItems.isEmpty {
                Text(L("暂无本地生成记录", "No local outputs yet"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 290)
            } else {
                ScrollView {
                    VStack(spacing: 3) {
                        ForEach(vm.localMediaItems) { item in
                            let selected = vm.currentMediaURL == item.url
                            Button {
                                vm.selectMedia(item.url)
                            } label: {
                                HStack(spacing: 7) {
                                    Image(systemName: item.isImage ? "photo" : "film")
                                        .font(.caption)
                                        .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.filename)
                                            .font(.caption.weight(.medium))
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        Text(item.createdAt.formatted(
                                            Date.FormatStyle(date: .abbreviated, time: .shortened, locale: displayLocale)
                                        ))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 4)
                                    if let el = item.elapsedSeconds, el > 0 {
                                        Text(formatDuration(el, compact: true))
                                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(selected ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.06))
                                            )
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selected ? Color.accentColor.opacity(0.15) : Color.clear)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.trailing, 2)
                }
                .compatScrollIndicatorMargins(.vertical, 2)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .frame(height: 330)
            }
        }
    }

    // MARK: - 右侧独立全高运行日志面板

    private func logLineColor(_ line: String) -> Color {
        let lower = line.lowercased()
        if line.contains("失败") || line.contains("错误") || line.contains("异常")
            || line.contains("ERROR") || lower.contains("failed") || lower.contains("error:")
            || lower.contains("exception") || lower.contains("traceback") {
            return Color(red: 0.98, green: 0.46, blue: 0.46)
        }
        if line.contains("───") {
            return Color(red: 0.46, green: 0.80, blue: 0.98)
        }
        if line.contains("%") || line.contains("已装载") || line.contains("成功") || line.contains("完成")
            || lower.contains("loaded") || lower.contains("succeeded") || lower.contains("successfully")
            || lower.contains("completed") || lower.contains("ready in vram") {
            return Color(red: 0.35, green: 0.92, blue: 0.55)
        }
        return Color(white: 0.87)
    }

    private func rightLogPanel(palette: StudioPalette) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // 实时任务摘要横条
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: isTaskStreaming ? "bolt.horizontal.circle.fill" : "info.circle")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(isTaskStreaming ? Color.accentColor : Color.secondary)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 3) {
                    Group {
                        if expandStatusMessage {
                            ScrollView {
                                Text(vm.displayStatusMessage)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }.frame(maxHeight: 220)
                        } else {
                            Text(vm.displayStatusMessage)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(.primary)
                    .help(vm.displayStatusMessage)
                    Button(expandStatusMessage ? L("收起详情", "Collapse") : L("展开全部", "Show Full Message")) {
                        expandStatusMessage.toggle()
                    }.buttonStyle(.borderless).font(.caption)

                    if vm.isDownloadingWeights || vm.isLoadingModel {
                        ProgressView(value: vm.modelTaskProgress)
                            .progressViewStyle(.linear)
                            .controlSize(.small)
                    } else if vm.isGenerating && vm.progressValue > 0 {
                        ProgressView(value: vm.progressValue)
                            .progressViewStyle(.linear)
                            .controlSize(.small)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(palette.sidebarCardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(palette.cardBorder, lineWidth: 1)
                    )
            )

            // 全高自适应深色终端流视口
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(Array(vm.liveConsoleLines.enumerated()), id: \.offset) { idx, line in
                            let renderedLine = vm.maskedConsoleDisplay(localizeConsoleLine(line))
                            Text(renderedLine)
                                .font(.system(size: 11.5, design: .monospaced))
                                .foregroundStyle(logLineColor(renderedLine))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                                .id(idx)
                        }
                    }
                    .padding(12)
                }
                .environment(\.colorScheme, .dark)
                .compatScrollIndicatorMargins(.all, 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(palette.logTerminalFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onAppear {
                    if !vm.liveConsoleLines.isEmpty {
                        proxy.scrollTo(vm.liveConsoleLines.count - 1, anchor: .bottom)
                    }
                }
                .compatOnChange(of: vm.liveConsoleLines) { newLines in
                    if !newLines.isEmpty {
                        proxy.scrollTo(newLines.count - 1, anchor: .bottom)
                    }
                }
            }
        }
        .padding(12)
    }

    private func utilizationButton(title: String, value: Double?, gpu: Bool) -> some View {
        Button {
            monitorGPU = gpu
            showProcessMonitor = true
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title).font(.caption.weight(.semibold))
                    Spacer()
                    Text(value.map { String(format: "%.1f%%", $0) } ?? "—").monospacedDigit().font(.caption)
                }
                ProgressView(value: (value ?? 0) / 100)
            }.padding(8).background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.045)))
        }
        .buttonStyle(.plain).disabled(!vm.isConnected)
        .help(L("点击查看云端进程监控；需启用并同步 API Key。— 表示暂不可用，不是 0%。", "Open cloud process monitoring; enable and sync the API key. — means unavailable, not 0%."))
    }
}

private extension View {
    @ViewBuilder
    func compatScrollIndicatorMargins(_ edges: Edge.Set = .all, _ length: CGFloat) -> some View {
        if #available(macOS 14.0, *) {
            self.contentMargins(edges, length, for: .scrollIndicators)
        } else {
            self
        }
    }

    @ViewBuilder
    func compatOnChange<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View {
        if #available(macOS 14.0, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else {
            self.onChange(of: value, perform: action)
        }
    }
}

// MARK: - 极简悬浮滚动条引擎（消除外接鼠标下的传统宽灰槽滚动条）

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

@MainActor
enum SleekScrollBarInstaller {
    private static var installed = false

    static func install() {
        guard !installed else { return }
        installed = true

        if let orig = class_getClassMethod(NSScroller.self, #selector(getter: NSScroller.preferredScrollerStyle)),
           let repl = class_getClassMethod(NSScroller.self, #selector(NSScroller.sleek_preferredScrollerStyle)) {
            method_exchangeImplementations(orig, repl)
        }

        if let origSet = class_getInstanceMethod(NSScrollView.self, #selector(setter: NSScrollView.scrollerStyle)),
           let replSet = class_getInstanceMethod(NSScrollView.self, #selector(NSScrollView.sleek_setScrollerStyle(_:))) {
            method_exchangeImplementations(origSet, replSet)
        }

        if let origTile = class_getInstanceMethod(NSScrollView.self, #selector(NSScrollView.tile)),
           let replTile = class_getInstanceMethod(NSScrollView.self, #selector(NSScrollView.sleek_tile)) {
            method_exchangeImplementations(origTile, replTile)
        }
    }
}

extension NSScroller {
    @objc fileprivate static func sleek_preferredScrollerStyle() -> NSScroller.Style {
        return .overlay
    }
}

extension NSScrollView {
    @objc fileprivate func sleek_setScrollerStyle(_ newStyle: NSScroller.Style) {
        self.sleek_setScrollerStyle(.overlay)
    }

    @objc fileprivate func sleek_tile() {
        if scrollerStyle != .overlay {
            self.sleek_setScrollerStyle(.overlay)
        }
        if !autohidesScrollers {
            autohidesScrollers = true
        }
        if let v = verticalScroller, v.controlSize != .small {
            v.controlSize = .small
        }
        if let h = horizontalScroller, h.controlSize != .small {
            h.controlSize = .small
        }

        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let desiredKnob: NSScroller.KnobStyle = isDark ? .light : .default
        if scrollerKnobStyle != desiredKnob {
            scrollerKnobStyle = desiredKnob
        }

        if let textView = documentView as? NSTextView {
            scrollerInsets = NSEdgeInsets(top: 3, left: 0, bottom: 3, right: 1)
            if textView.textContainerInset.height < 3 {
                textView.textContainerInset = NSSize(width: 2, height: 4)
            }
        }

        self.sleek_tile()
    }
}

// MARK: - 窗口顶栏拖拽与红绿灯对齐组件

struct WindowDragHandle: NSViewRepresentable {
    final class DragView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
    }

    func makeNSView(context: Context) -> NSView {
        DragView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct TitlebarConfigurator: NSViewRepresentable {
    let headerHeight: CGFloat

    final class ConfigView: NSView {
        var headerHeight: CGFloat = 40
        private var resizeObserver: NSObjectProtocol?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            configureWindow()
            if let resizeObserver {
                NotificationCenter.default.removeObserver(resizeObserver)
            }
            if let win = window {
                resizeObserver = NotificationCenter.default.addObserver(
                    forName: NSWindow.didResizeNotification,
                    object: win,
                    queue: .main
                ) { [weak self] _ in
                    self?.alignTrafficLights()
                }
            }
        }

        override func layout() {
            super.layout()
            alignTrafficLights()
        }

        private func configureWindow() {
            guard let win = window else { return }
            win.titleVisibility = .hidden
            win.titlebarAppearsTransparent = true
            win.styleMask.insert(.fullSizeContentView)
            win.isMovableByWindowBackground = false
            alignTrafficLights()
        }

        func alignTrafficLights() {
            guard let win = window else { return }
            let types: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
            for (idx, bType) in types.enumerated() {
                guard let btn = win.standardWindowButton(bType),
                      let superview = btn.superview else { continue }
                var frame = btn.frame
                frame.origin.x = 15.0 + CGFloat(idx) * 20.0
                if superview.isFlipped {
                    frame.origin.y = (headerHeight - frame.height) * 0.5
                } else {
                    frame.origin.y = superview.bounds.height - (headerHeight + frame.height) * 0.5
                }
                btn.setFrameOrigin(frame.origin)
            }
        }

        deinit {
            if let resizeObserver {
                NotificationCenter.default.removeObserver(resizeObserver)
            }
        }
    }

    func makeNSView(context: Context) -> ConfigView {
        let v = ConfigView()
        v.headerHeight = headerHeight
        return v
    }

    func updateNSView(_ nsView: ConfigView, context: Context) {
        nsView.headerHeight = headerHeight
        nsView.alignTrafficLights()
    }
}

// MARK: - macOS 应用程序入口

@main
struct EasyColabApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var i18n = LanguageManager.shared

    init() {
        Self.migrateLegacyDefaultsIfNeeded()
        SleekScrollBarInstaller.install()
    }

    private static func migrateLegacyDefaultsIfNeeded() {
        let std = UserDefaults.standard
        guard !std.bool(forKey: "migratedToEasyColabSuite") else { return }
        for suiteName in ["app.aevix.studio.macos", "com.colab.aistudio.macos", "com.minimax.h3studio.macos"] {
            if let legacy = UserDefaults(suiteName: suiteName) {
                if std.string(forKey: "colabServerURL") == nil,
                   let url = legacy.string(forKey: "colabServerURL"), !url.isEmpty {
                    std.set(url, forKey: "colabServerURL")
                }
                if std.double(forKey: "totalBudgetCU") == 0 {
                    let cu = legacy.double(forKey: "totalBudgetCU")
                    if cu > 0 { std.set(cu, forKey: "totalBudgetCU") }
                }
                if std.string(forKey: "apiAccessKey") == nil,
                   let key = legacy.string(forKey: "apiAccessKey"), !key.isEmpty {
                    std.set(key, forKey: "apiAccessKey")
                }
                if std.object(forKey: "apiKeyEnabled") == nil,
                   legacy.object(forKey: "apiKeyEnabled") != nil {
                    std.set(legacy.bool(forKey: "apiKeyEnabled"), forKey: "apiKeyEnabled")
                }
                if std.object(forKey: "qwenContextLengthK") == nil,
                   legacy.integer(forKey: "qwenContextLengthK") >= 4 {
                    std.set(legacy.integer(forKey: "qwenContextLengthK"), forKey: "qwenContextLengthK")
                }
                if std.object(forKey: "idleTimeoutMinutes") == nil,
                   legacy.object(forKey: "idleTimeoutMinutes") != nil {
                    std.set(legacy.integer(forKey: "idleTimeoutMinutes"), forKey: "idleTimeoutMinutes")
                }
                if std.string(forKey: "reasoningEffort") == nil,
                   let eff = legacy.string(forKey: "reasoningEffort"), !eff.isEmpty {
                    std.set(eff, forKey: "reasoningEffort")
                }
                if std.dictionary(forKey: "mediaElapsedSecondsMap") == nil,
                   let map = legacy.dictionary(forKey: "mediaElapsedSecondsMap") {
                    std.set(map, forKey: "mediaElapsedSecondsMap")
                }
            }
        }
        std.set(true, forKey: "migratedToEasyColabSuite")
    }

    var body: some Scene {
        WindowGroup("EasyColab") {
            MainStudioView()
                .frame(minWidth: 1300, minHeight: 860)
        }
        .defaultSize(width: 1480, height: 900)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .sidebar) {
                Button(L("切换语言 (中文 / English)", "Switch Language (中文 / English)")) {
                    LanguageManager.shared.toggle()
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .help) {
                Button(L("EasyColab 新手引导与使用指南", "EasyColab Quick Start & User Guide")) {
                    NotificationCenter.default.post(name: .openEasyColabGuide, object: nil)
                }
                .keyboardShortcut("/", modifiers: [.command, .shift])
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        SleekScrollBarInstaller.install()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
