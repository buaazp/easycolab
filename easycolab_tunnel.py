"""Optional Cloudflare named tunnel shared by the server and headless bridge."""

import atexit
import base64
import json
import os
import re
import socket
import subprocess
import threading
import time
import urllib.error
import urllib.request
from collections import deque


def read_tunnel_config(environ):
    public_url = environ.get("EASYCOLAB_PUBLIC_URL", "").strip()
    token = environ.pop("CLOUDFLARE_TUNNEL_TOKEN", "").strip()
    if not public_url and not token:
        return "", ""
    if not public_url or not token:
        raise ValueError("EASYCOLAB_PUBLIC_URL 和 CLOUDFLARE_TUNNEL_TOKEN 必须同时配置 (both required)")
    hostname = re.fullmatch(
        r"https://((?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+"
        r"[a-zA-Z](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)/?",
        public_url,
    )
    if not hostname or len(hostname.group(1)) > 253:
        raise ValueError("自定义域名格式错误：需要 https://ai.example.com，不含端口、路径或参数 (HTTPS hostname only)")
    if any(char.isspace() for char in token) or "\x00" in token:
        raise ValueError("Tunnel Token 格式错误：请只填写 Token，不要粘贴安装命令 (token only)")
    return "https://" + hostname.group(1).lower(), token


def redact_diagnostic(text, secrets=()):
    sensitive_values = set(value for value in secrets if value)
    for value in tuple(sensitive_values):
        try:
            decoded = json.loads(base64.b64decode(value, validate=True))
            if isinstance(decoded, dict) and isinstance(decoded.get("s"), str) and decoded["s"]:
                sensitive_values.add(decoded["s"])
        except (ValueError, UnicodeError):
            pass
    for value in sorted(sensitive_values, key=len, reverse=True):
        text = text.replace(value, "[REDACTED]")
    text = re.sub(r"(?i)\bBearer\s+[^\s\"']+", "Bearer [REDACTED]", text)
    text = re.sub(
        r"(?i)(\b(?:[\w-]*token|[\w-]*secret|password|authorization|api[-_]?key)\b[\"']?\s*[:=]\s*)"
        r"(?:\"[^\"]*\"|'[^']*'|[^\s,;]+)",
        r"\1[REDACTED]",
        text,
    )
    return re.sub(r"\x1b\[[0-9;]*[a-zA-Z]", "", text)


class CloudflareTunnel:
    def __init__(self):
        self.process = None
        self._log_lines = deque(maxlen=20)
        self._log_thread = None

    def start(self, binary, token, timeout=60):
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            metrics_port = listener.getsockname()[1]
        tunnel_env = os.environ.copy()
        tunnel_env.pop("CLOUDFLARE_TUNNEL_TOKEN", None)
        tunnel_env.pop("TUNNEL_TOKEN_FILE", None)
        tunnel_env["TUNNEL_TOKEN"] = token
        self.process = subprocess.Popen(
            [binary, "tunnel", "--no-autoupdate", "--loglevel", "info", "--metrics", f"127.0.0.1:{metrics_port}",
             "--tag", "easycolab-main=1", "run"],
            env=tunnel_env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            bufsize=1,
        )
        atexit.register(self.stop)
        self._log_lines.clear()
        self._log_thread = threading.Thread(target=self._read_logs, args=(self.process.stdout, token), daemon=True)
        self._log_thread.start()
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
        deadline = time.monotonic() + timeout
        try:
            while time.monotonic() < deadline:
                exit_code = self.process.poll()
                if exit_code is not None:
                    self._log_thread.join(timeout=2)
                    raise RuntimeError(f"Cloudflare 连接器退出 (exit={exit_code})。{self._diagnostic_tail()}")
                try:
                    with opener.open(f"http://127.0.0.1:{metrics_port}/ready", timeout=2) as response:
                        if response.status == 200:
                            return
                except (OSError, urllib.error.URLError):
                    pass
                time.sleep(0.5)
            raise RuntimeError(f"Cloudflare 连接超时 ({timeout}s)，请检查出站网络。{self._diagnostic_tail()}")
        except BaseException:
            self.stop()
            raise

    def _read_logs(self, stream, token):
        try:
            for line in stream:
                clean = redact_diagnostic(line, (token,)).strip()
                if clean:
                    self._log_lines.append(clean[:2000])
        finally:
            stream.close()

    def _diagnostic_tail(self):
        return "连接器日志 (sanitized):\n" + ("\n".join(self._log_lines)[-4000:] or "无输出 (no output)")

    def stop(self):
        process, self.process = self.process, None
        if process is not None and process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
        if self._log_thread is not None:
            self._log_thread.join(timeout=2)


def exit_on_sigterm(signum, frame):
    raise SystemExit(0)
