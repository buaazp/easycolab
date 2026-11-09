"""Read-only process monitoring and local browser-based Drive authorization dialogs."""

import json
import subprocess
import threading
import time
import urllib.parse
import webbrowser

import requests
from PySide6.QtCore import Qt, QTimer, Signal
from PySide6.QtWidgets import (
    QCheckBox, QDialog, QFileDialog, QHBoxLayout, QLabel, QLineEdit, QPushButton,
    QTabWidget, QTableWidget, QTableWidgetItem, QVBoxLayout, QWidget,
)

from windows_app.models import tr


class DriveConnectionDialog(QDialog):
    event = Signal(object)

    def __init__(self, viewmodel, parent=None):
        super().__init__(parent)
        self.vm = viewmodel
        self.process = None
        self.lock = threading.Lock()
        self.cancelled = threading.Event()
        self.busy = False
        self.setWindowTitle(tr("连接 Google Drive", "Connect Google Drive"))
        self.resize(660, 290)
        layout = QVBoxLayout(self)
        hint = QLabel(tr(
            "与 Colab 登录分开授权。自动复用已有 rclone 客户端信息；新机器导入自己的桌面应用 OAuth JSON 后，通过浏览器授权，无需手工配置 rclone。",
            "Separate from Colab login. Reuse existing rclone client settings, or import your desktop OAuth JSON once on a new computer, then authorize in your browser. No manual rclone setup.",
        ))
        hint.setWordWrap(True)
        layout.addWidget(hint)
        self.full_access = QCheckBox(tr("访问已有云盘文件（完整 Drive 权限）", "Access existing Drive files (full Drive scope)"))
        layout.addWidget(self.full_access)
        note = QLabel(tr(
            "关闭时请求 drive.file，仅访问本应用创建/获授权的文件。Testing 授权约 7 天到期，可重新连接。凭据保存在本机用户目录，不自动跨机器同步。",
            "Off uses drive.file for app-created/authorized files. Testing grants expire after seven days; reconnect to renew. Credentials stay in the local user profile, without automatic cross-machine sync.",
        ))
        note.setWordWrap(True)
        layout.addWidget(note)
        self.status = QLabel()
        self.status.setWordWrap(True)
        self.status.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse)
        layout.addWidget(self.status)
        buttons = QHBoxLayout()
        self.import_button = QPushButton(tr("导入客户端 JSON…", "Import Client JSON…"))
        self.import_button.clicked.connect(self.import_client)
        self.connect_button = QPushButton(tr("连接 / 重新授权", "Connect / Reauthorize"))
        self.connect_button.clicked.connect(lambda: self.run_command(["drive_connect"] + (["--full-access"] if self.full_access.isChecked() else [])))
        self.cancel_button = QPushButton(tr("取消 / 关闭", "Cancel / Close"))
        self.cancel_button.clicked.connect(self.reject)
        for button in (self.import_button, self.connect_button, self.cancel_button):
            buttons.addWidget(button)
        layout.addLayout(buttons)
        self.event.connect(self.receive_event)
        QTimer.singleShot(0, lambda: self.run_command(["drive_status"]))

    def import_client(self):
        path, _ = QFileDialog.getOpenFileName(self, tr("选择桌面应用 OAuth JSON", "Select desktop OAuth JSON"), "", "JSON (*.json)")
        if path:
            self.run_command(["drive_import", "--client-json", path])

    def run_command(self, arguments):
        if self.busy or self.cancelled.is_set():
            return
        self.busy = True
        self.import_button.setEnabled(False)
        self.connect_button.setEnabled(False)
        self.full_access.setEnabled(False)
        self.status.setText(tr("正在准备 Drive 授权…", "Preparing Drive authorization…"))

        def worker():
            process = None
            try:
                command = self.vm._resolve_python_for_bridge(install_if_missing=True) + arguments
                environment = self.vm._bridge_env()
                environment["PYTHONUNBUFFERED"] = "1"
                with self.lock:
                    if self.cancelled.is_set():
                        return
                    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, encoding="utf-8", env=environment,
                                               creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
                    self.process = process
                for line in process.stdout:
                    if self.cancelled.is_set():
                        break
                    if line.startswith("DRIVE_AUTH_URL:"):
                        self.event.emit({"url": line[len("DRIVE_AUTH_URL:"):].strip()})
                    elif line.startswith("DRIVE_RESULT:"):
                        self.event.emit(json.loads(line[len("DRIVE_RESULT:"):]))
                process.wait(timeout=10)
            except Exception:
                self.event.emit({"ok": False, "message": tr("Drive 授权未完成，请检查配置及网络后重试。", "Drive authorization did not complete. Check configuration/network and retry.")})
            finally:
                if process is not None and process.poll() is None:
                    process.terminate()
                self.event.emit({"finished": True})

        threading.Thread(target=worker, daemon=True).start()

    def receive_event(self, event):
        if self.cancelled.is_set():
            return
        if "url" in event:
            parsed = urllib.parse.urlsplit(event["url"])
            if parsed.scheme == "https" and parsed.hostname == "accounts.google.com":
                webbrowser.open(event["url"])
                self.status.setText(tr("请在浏览器完成 Google Drive 授权（3 分钟内）。", "Complete Google Drive consent in your browser within three minutes."))
        elif event.get("finished"):
            self.busy = False
            self.import_button.setEnabled(True)
            self.connect_button.setEnabled(True)
            self.full_access.setEnabled(True)
        else:
            self.status.setText(str(event.get("message", "")))
            if "full_access" in event:
                self.full_access.setChecked(bool(event["full_access"]))

    def reject(self):
        self.cancelled.set()
        with self.lock:
            if self.process is not None and self.process.poll() is None:
                self.process.terminate()
        super().reject()

    def closeEvent(self, event):
        self.reject()
        event.accept()


class ProcessMonitorDialog(QDialog):
    result = Signal(object)

    def __init__(self, base_url, api_key, gpu_mode=False, parent=None):
        super().__init__(parent)
        self.base_url, self.api_key = base_url, api_key
        self.active, self.inflight = True, False
        self.setWindowTitle(tr("云端进程监控 · 只读", "Cloud Process Monitor · Read-only"))
        self.resize(980, 580)
        layout = QVBoxLayout(self)
        self.summary = QLabel()
        self.summary.setWordWrap(True)
        layout.addWidget(self.summary)
        self.tabs = QTabWidget()
        self.cpu_table = self.table(["PID", tr("进程", "Process"), tr("状态", "State"), "CPU %", "RAM MiB", tr("线程", "Threads")])
        self.gpu_table = self.table(["PID", tr("进程", "Process"), "GPU %", "VRAM MiB", "GPU UUID"])
        self.tabs.addTab(self.cpu_table, "CPU / htop")
        self.tabs.addTab(self.gpu_table, "GPU / nvitop")
        self.tabs.setCurrentIndex(1 if gpu_mode else 0)
        layout.addWidget(self.tabs)
        self.filter = QLineEdit()
        self.filter.setPlaceholderText(tr("按名称或 PID 过滤", "Filter by name or PID"))
        self.filter.textChanged.connect(self.filter_rows)
        layout.addWidget(self.filter)
        note = QLabel(tr(
            "进程 CPU 以单核 100% 计；最多显示前 200 个进程。— 表示不支持或正在采样。仅显示进程名，不暴露命令行、环境变量，也不提供终止操作。",
            "Process CPU uses 100% per core. Top 200 processes; — means unsupported or sampling. Names only, without command lines, environments, or termination controls.",
        ))
        note.setWordWrap(True)
        layout.addWidget(note)
        self.result.connect(self.apply_result)
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.refresh)
        self.timer.start(3000)
        self.refresh()

    def table(self, headers):
        table = QTableWidget(0, len(headers))
        table.setHorizontalHeaderLabels(headers)
        table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        table.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        table.setSortingEnabled(True)
        table.horizontalHeader().setStretchLastSection(True)
        return table

    def refresh(self):
        if not self.active or self.inflight:
            return
        self.inflight = True

        def worker():
            try:
                response = requests.get(self.base_url + "/minimax_api/processes", headers={"Authorization": "Bearer " + self.api_key}, timeout=12)
                if response.status_code == 200:
                    data = response.json()
                else:
                    data = {"error": tr(f"监控不可用（HTTP {response.status_code}）：请更新服务端，并启用/同步 API Key。", f"Monitor unavailable (HTTP {response.status_code}): update server and enable/sync the API key.")}
            except Exception:
                data = {"error": tr("监控连接失败，正在重试，不显示过期数据。", "Monitor disconnected; retrying without displaying stale data.")}
            self.result.emit(data)

        threading.Thread(target=worker, daemon=True).start()

    def fill(self, table, rows):
        table.setSortingEnabled(False)
        table.setRowCount(len(rows))
        for row_index, values in enumerate(rows):
            for column_index, value in enumerate(values):
                item = QTableWidgetItem()
                item.setData(Qt.ItemDataRole.DisplayRole, value if value is not None else "—")
                table.setItem(row_index, column_index, item)
        table.setSortingEnabled(True)
        table.resizeColumnsToContents()

    def apply_result(self, data):
        self.inflight = False
        if not self.active:
            return
        if "error" in data:
            self.summary.setText(str(data["error"]))
            self.cpu_table.setRowCount(0)
            self.gpu_table.setRowCount(0)
            return
        timestamp = data.get("process_sampled_at")
        sampled = time.strftime("%H:%M:%S", time.localtime(timestamp)) if timestamp else tr("正在采样…", "Sampling…")
        gpu_text = " | ".join(f"GPU {item['index']} {item['name']} {item.get('utilization_pct', '—')}% · {item.get('memory_used_mib', '—')}/{item.get('memory_total_mib', '—')} MiB" for item in data.get("gpus", []))
        self.summary.setText(f"{sampled} · CPU {data.get('cpu_utilization_pct', '—')}% · {data.get('cpu_count', '—')} CPUs · {data.get('process_total', 0)} processes\n{gpu_text}")
        self.fill(self.cpu_table, [[row.get(key) for key in ("pid", "name", "state", "cpu_pct", "rss_mib", "threads")] for row in data.get("processes", [])])
        self.fill(self.gpu_table, [[row.get(key) for key in ("pid", "name", "gpu_pct", "memory_mib", "gpu_uuid")] for row in data.get("gpu_processes", [])])
        self.filter_rows()

    def filter_rows(self):
        text = self.filter.text().casefold()
        for table in (self.cpu_table, self.gpu_table):
            for row in range(table.rowCount()):
                values = " ".join(table.item(row, column).text() for column in (0, 1) if table.item(row, column))
                table.setRowHidden(row, text not in values.casefold())

    def done(self, result):
        self.active = False
        self.timer.stop()
        super().done(result)

    def closeEvent(self, event):
        self.active = False
        self.timer.stop()
        super().closeEvent(event)
