import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct DriveConnectionResult: Decodable {
    var ok: Bool
    var authorized: Bool?
    var client_configured: Bool?
    var message: String
    var full_access: Bool?
}

@MainActor
final class DriveConnectionController: ObservableObject {
    @Published var busy = false
    @Published var authorized = false
    @Published var message = ""
    @Published var fullAccess = false
    private var process: Process?
    private var operation = UUID()

    func run(python: String, script: String, arguments: [String]) {
        guard !busy else { return }
        busy = true
        message = "正在处理 Drive 授权 / Preparing Drive authorization…"
        operation = UUID()
        let identifier = operation
        let child = Process()
        child.executableURL = URL(fileURLWithPath: python)
        child.arguments = ["-u", script] + arguments
        let pipe = Pipe()
        child.standardOutput = pipe
        child.standardError = FileHandle.nullDevice
        process = child
        do { try child.run() } catch {
            busy = false
            process = nil
            message = "无法启动 Drive 授权组件 / Cannot start Drive authorization."
            return
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var pending = Data()
            while true {
                let chunk = pipe.fileHandleForReading.availableData
                if chunk.isEmpty { break }
                pending.append(chunk)
                while let newline = pending.firstIndex(of: 10) {
                    let line = String(decoding: pending[..<newline], as: UTF8.self)
                    pending.removeSubrange(...newline)
                    DispatchQueue.main.async { self?.consume(line, identifier: identifier) }
                }
            }
            child.waitUntilExit()
            DispatchQueue.main.async {
                guard let self, self.operation == identifier else { return }
                self.busy = false
                self.process = nil
                if self.message.hasPrefix("正在处理") {
                    self.message = "授权未完成，请重试 / Authorization did not complete; retry."
                }
            }
        }
    }

    private func consume(_ line: String, identifier: UUID) {
        guard operation == identifier else { return }
        if line.hasPrefix("DRIVE_AUTH_URL:"), let url = URL(string: String(line.dropFirst(15))), url.scheme == "https", url.host == "accounts.google.com" {
            message = "请在浏览器选择账号并同意 Drive 权限，3 分钟内完成 / Complete Drive consent in your browser within 3 minutes."
            NSWorkspace.shared.open(url)
        } else if line.hasPrefix("DRIVE_RESULT:"), let data = String(line.dropFirst(13)).data(using: .utf8), let result = try? JSONDecoder().decode(DriveConnectionResult.self, from: data) {
            if let saved = result.authorized { authorized = saved }
            if let fullAccess = result.full_access { self.fullAccess = fullAccess }
            message = result.message
        }
    }

    func cancel() {
        operation = UUID()
        process?.terminate()
        process = nil
        busy = false
        message = "已取消，已有授权保留 / Cancelled; previous credentials kept."
    }
}

struct DriveConnectionView: View {
    @ObservedObject var controller: DriveConnectionController
    let chinese: Bool
    let run: ([String]) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(chinese ? "连接 Google Drive" : "Connect Google Drive").font(.title2.bold())
            Text(chinese ? "与 Colab 登录分开授权。当前 Mac 自动复用已有 rclone 客户端信息；新机器先导入你自己的桌面应用 OAuth JSON，再通过浏览器授权，无需安装或手工配置 rclone。" : "Separate from Colab login. Reuse existing rclone OAuth client settings here; on another computer, import your desktop OAuth client JSON once, then authorize in the browser. No manual rclone setup.")
            Toggle(chinese ? "访问已有云盘文件（完整 Drive 权限）" : "Access existing Drive files (full Drive scope)", isOn: $controller.fullAccess).disabled(controller.busy)
            Text(chinese ? "关闭时仅请求 drive.file，访问本 OAuth 应用创建/获授权的文件。Testing 授权约 7 天到期，点击连接可重新授权。凭据保存在本机用户目录，不会自动同步到其他机器。" : "Off requests drive.file for app-created/authorized files only. Testing grants expire after seven days; reconnect to renew. Credentials stay in your local user profile, not automatically synced to other machines.").font(.caption).foregroundStyle(.secondary)
            Text(controller.message).fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
            if controller.busy { ProgressView() }
            HStack {
                Button(chinese ? "导入客户端 JSON…" : "Import Client JSON…") {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.json]
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let path = panel.url?.path { run(["drive_import", "--client-json", path]) }
                }.disabled(controller.busy)
                Button(chinese ? "连接 / 重新授权" : "Connect / Reauthorize") {
                    run(["drive_connect"] + (controller.fullAccess ? ["--full-access"] : []))
                }.buttonStyle(.borderedProminent).disabled(controller.busy)
                Spacer()
                if controller.busy { Button(chinese ? "取消授权" : "Cancel Authorization") { controller.cancel() } }
                Button(chinese ? "关闭" : "Close") { dismiss() }.keyboardShortcut(.cancelAction)
            }
        }
        .padding(24).frame(width: 630)
        .task { run(["drive_status"]) }
        .onDisappear { if controller.busy { controller.cancel() } }
    }
}

struct HostProcessRow: Decodable, Identifiable {
    var pid: Int
    var name: String
    var state: String
    var cpu_pct: Double?
    var rss_mib: Double
    var threads: Int
    var id: Int { pid }
}

struct GPUProcessRow: Decodable, Identifiable {
    var pid: Int
    var name: String
    var memory_mib: Double?
    var gpu_pct: Double?
    var gpu_uuid: String
    var id: String { "\(gpu_uuid):\(pid)" }
}

struct MonitoredGPU: Decodable, Identifiable {
    var index: Int
    var name: String
    var utilization_pct: Double?
    var memory_used_mib: Double?
    var memory_total_mib: Double?
    var temperature_c: Double?
    var power_w: Double?
    var id: Int { index }
}

struct ProcessSnapshot: Decodable {
    var cpu_utilization_pct: Double?
    var cpu_count: Int
    var gpus: [MonitoredGPU]
    var processes: [HostProcessRow]
    var gpu_processes: [GPUProcessRow]
    var process_sampled_at: Double?
    var process_total: Int
    var truncated: Bool
}

private func monitorNumber(_ value: Double?, suffix: String = "") -> String {
    value.map { String(format: "%.1f", $0) + suffix } ?? "—"
}

struct ProcessMonitorView: View {
    let baseURL: String
    let apiKey: String
    let chinese: Bool
    @State var gpuMode: Bool
    @State private var snapshot: ProcessSnapshot?
    @State private var error = ""
    @State private var filter = ""
    @State private var order = "cpu"
    @Environment(\.dismiss) private var dismiss

    private var rows: [HostProcessRow] {
        (snapshot?.processes ?? []).filter { filter.isEmpty || $0.name.localizedCaseInsensitiveContains(filter) || String($0.pid).contains(filter) }.sorted {
            if order == "memory" { return $0.rss_mib > $1.rss_mib }
            if order == "pid" { return $0.pid < $1.pid }
            return ($0.cpu_pct ?? -1) > ($1.cpu_pct ?? -1)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(chinese ? "云端进程监控 · 只读" : "Cloud Process Monitor · Read-only").font(.headline)
                Spacer()
                Button(chinese ? "关闭" : "Close") { dismiss() }.keyboardShortcut(.cancelAction)
            }
            Picker("Monitor", selection: $gpuMode) {
                Text("CPU / htop").tag(false)
                Text("GPU / nvitop").tag(true)
            }.pickerStyle(.segmented)
            if !error.isEmpty { Text(error).foregroundStyle(.orange).textSelection(.enabled) }
            if let snapshot {
                if let timestamp = snapshot.process_sampled_at {
                    Text((chinese ? "采样时间：" : "Sampled: ") + Date(timeIntervalSince1970: timestamp).formatted(date: .omitted, time: .standard)).font(.caption).foregroundStyle(.secondary)
                } else {
                    Text(chinese ? "正在采样，首次 CPU 读数需两次采样…" : "Sampling; CPU rates need two samples…")
                }
                if gpuMode {
                    ForEach(snapshot.gpus) { gpu in
                        Text("GPU \(gpu.index) · \(gpu.name) · \(monitorNumber(gpu.utilization_pct, suffix: "%")) · \(monitorNumber(gpu.memory_used_mib))/\(monitorNumber(gpu.memory_total_mib)) MiB · \(monitorNumber(gpu.temperature_c, suffix: "°C")) · \(monitorNumber(gpu.power_w, suffix: " W"))").font(.caption)
                    }
                    Table(snapshot.gpu_processes.filter { filter.isEmpty || $0.name.localizedCaseInsensitiveContains(filter) || String($0.pid).contains(filter) }) {
                        TableColumn("PID") { Text(String($0.pid)) }.width(70)
                        TableColumn(chinese ? "进程" : "Process", value: \.name)
                        TableColumn("GPU %") { Text(monitorNumber($0.gpu_pct)) }
                        TableColumn(chinese ? "显存 MiB" : "VRAM MiB") { Text(monitorNumber($0.memory_mib)) }
                        TableColumn("GPU UUID", value: \.gpu_uuid)
                    }
                    Text(chinese ? "GPU 进程利用率取自 nvidia-smi pmon；驱动不支持时显示 —，不是 0%。" : "Per-process GPU utilization uses nvidia-smi pmon; unsupported values show —, not 0%.").font(.caption)
                } else {
                    HStack {
                        Text("CPU \(monitorNumber(snapshot.cpu_utilization_pct, suffix: "%")) · \(snapshot.cpu_count) logical CPUs · \(snapshot.process_total) processes")
                        Spacer()
                        Picker(chinese ? "排序" : "Sort", selection: $order) {
                            Text("CPU").tag("cpu")
                            Text("RAM").tag("memory")
                            Text("PID").tag("pid")
                        }.frame(width: 170)
                    }.font(.caption)
                    Table(rows) {
                        TableColumn("PID") { Text(String($0.pid)) }.width(65)
                        TableColumn(chinese ? "进程" : "Process", value: \.name)
                        TableColumn(chinese ? "状态" : "State", value: \.state).width(50)
                        TableColumn("CPU %") { Text(monitorNumber($0.cpu_pct)) }
                        TableColumn("RAM MiB") { Text(monitorNumber($0.rss_mib)) }
                        TableColumn(chinese ? "线程" : "Threads") { Text(String($0.threads)) }
                    }
                    Text(chinese ? "进程 CPU 以单核 100% 计，多线程可超过 100%；最多显示前 200 个进程，不显示命令行/环境变量。" : "Process CPU uses 100% per core and can exceed 100%. Top 200 processes; no command lines or environment variables.").font(.caption)
                }
            } else { Spacer() }
            TextField(chinese ? "按名称或 PID 过滤" : "Filter by name or PID", text: $filter).textFieldStyle(.roundedBorder)
        }
        .padding(20)
        .frame(minWidth: 820, idealWidth: 900, minHeight: 510, idealHeight: 590)
        .task {
            while !Task.isCancelled {
                await refresh()
                do { try await Task.sleep(nanoseconds: 3_000_000_000) } catch { break }
            }
        }
    }

    @MainActor private func refresh() async {
        guard let url = URL(string: baseURL + "/minimax_api/processes") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("Bearer " + apiKey, forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard !Task.isCancelled else { return }
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard code == 200 else {
                snapshot = nil
                error = chinese ? "监控不可用（HTTP \(code)）：请更新服务端，并启用/同步 API Key。" : "Monitor unavailable (HTTP \(code)): update server and enable/sync the API key."
                return
            }
            snapshot = try JSONDecoder().decode(ProcessSnapshot.self, from: data)
            error = ""
        } catch {
            guard !Task.isCancelled else { return }
            snapshot = nil
            self.error = chinese ? "监控连接失败，正在重试；不会显示过期数据。" : "Monitor disconnected; retrying without displaying stale data."
        }
    }
}
