"""Byte-based model transfer tracking and independent rclone Drive verification."""

import base64
import hashlib
import json
import os
import re
import secrets
import socket
import subprocess
import threading
import time
import urllib.request


RC_STATE_PATH = "/content/.easycolab_drive_monitor.json"


def prepare_mount_monitor(mount_path, source):
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        port = listener.getsockname()[1]
    user, password = "easycolab-monitor", secrets.token_urlsafe(32)
    config = {"url": f"http://127.0.0.1:{port}", "user": user, "password": password, "mount": mount_path, "source": source}
    descriptor = os.open(RC_STATE_PATH, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
        os.chmod(RC_STATE_PATH, 0o600)
        json.dump(config, stream)
    environment = os.environ.copy()
    environment.update(RCLONE_RC_USER=user, RCLONE_RC_PASS=password, RCLONE_RC_NO_AUTH="false")
    return ["--rc", "--rc-addr", f"127.0.0.1:{port}"], environment


def find_rclone_mount(directory, mountinfo="/proc/self/mountinfo"):
    directory = os.path.abspath(directory)
    candidates = []
    try:
        with open(mountinfo, encoding="utf-8") as stream:
            for line in stream:
                left, separator, right = line.partition(" - ")
                fields, filesystem = left.split(), right.split()
                if not separator or len(fields) < 5 or len(filesystem) < 2 or filesystem[0] != "fuse.rclone":
                    continue
                decode = lambda value: re.sub(r"\\([0-7]{3})", lambda match: chr(int(match.group(1), 8)), value)
                mount_path, source = decode(fields[4]), decode(filesystem[1])
                cache_source = source
                source = re.sub(r"\{[A-Za-z0-9_-]+\}(?=:)", "", source, count=1)
                if not re.match(r"^[A-Za-z0-9_ -]+:", source) or os.path.commonpath([directory, mount_path]) != mount_path:
                    continue
                relative = os.path.relpath(directory, mount_path)
                relative = "" if relative == "." else relative.replace(os.sep, "/")
                candidates.append({"path": mount_path, "source": source, "cache_source": cache_source, "relative": relative,
                                   "remote": source.rstrip("/") + ("/" + relative if relative else "")})
    except OSError:
        return None
    return max(candidates, key=lambda item: len(item["path"]), default=None)


def model_file_sizes(spec, directory, token=""):
    sizes = dict(spec.get("file_sizes", {}))
    filenames = [name for name, description in spec["files"]]
    missing = [name for name in filenames if not sizes.get(name)]
    for name in missing[:]:
        path = os.path.join(directory, name)
        if os.path.isfile(path) and os.path.getsize(path) > 65536:
            sizes[name] = os.path.getsize(path)
            missing.remove(name)
    if missing:
        from huggingface_hub import HfApi
        try:
            info = HfApi().model_info(spec["repo_id"], revision=spec.get("revision", "main"), files_metadata=True, token=token or None)
        except Exception:
            raise RuntimeError("无法取得权重大小，请检查 Hugging Face 授权、仓库访问条款和网络。") from None
        sizes.update({entry.rfilename: entry.size for entry in info.siblings if entry.rfilename in missing and entry.size})
    if any(not isinstance(sizes.get(name), int) or sizes[name] <= 0 for name in filenames):
        raise RuntimeError("无法取得完整权重大小，暂不开始下载；请检查 HF 授权及网络后重试。")
    return {name: sizes[name] for name in filenames}


class ModelTransfer:
    def __init__(self, model_id, directory, sizes, drive, mount=None):
        self.model_id = model_id
        self.directory = directory
        self.sizes = dict(sizes)
        self.completed = {name: 0 for name in sizes}
        self.drive = drive
        self.mount = mount
        self.required = dict(sizes)
        self.manifest_md5 = ""
        self.download_finished = False
        self.uploaded = 0
        self.confirmed = 0
        self.upload_state = "uploading" if mount and drive else ("unavailable" if drive else "not_required")
        self.message = "等待 Drive 上传并校验；不要释放实例。" if mount else (
            "当前挂载不支持独立远端校验，不能确认已持久化；请使用桌面端 rclone 挂载。" if drive else "实例临时存储，释放后会丢失。"
        )
        self.lock = threading.RLock()
        self.stop_event = threading.Event()
        self.verified_event = threading.Event()
        self.thread = None
        self.checked_at = 0.0
        self.upload_live = False

    def record(self, filename, completed):
        with self.lock:
            if filename in self.sizes:
                self.completed[filename] = max(0, min(int(completed), self.sizes[filename]))

    def snapshot(self):
        with self.lock:
            return {
                "transfer_model_id": self.model_id,
                "download_completed_bytes": sum(self.completed.values()),
                "download_total_bytes": sum(self.sizes.values()),
                "upload_completed_bytes": self.uploaded,
                "upload_confirmed_bytes": self.confirmed,
                "upload_total_bytes": sum(self.sizes.values()) if self.drive else 0,
                "upload_state": self.upload_state,
                "upload_live": self.upload_live,
                "transfer_message": self.message,
            }

    def start(self):
        with self.lock:
            if self.mount and self.thread is None:
                self.thread = threading.Thread(target=self._monitor, daemon=True)
                self.thread.start()

    def cancel(self):
        self.stop_event.set()

    def prepare_confirmation(self):
        manifest_path = os.path.join(self.directory, ".easycolab-metadata.json")
        required = dict(self.sizes)
        manifest_md5 = ""
        if os.path.isfile(manifest_path):
            with open(manifest_path, "rb") as stream:
                payload = stream.read()
            manifest = json.loads(payload)
            for name, size in manifest["files"].items():
                if os.path.isabs(name) or os.path.normpath(name) != name or name.startswith("..") or not isinstance(size, int) or size <= 0:
                    raise ValueError("Invalid metadata manifest")
                required[name] = size
            required[".easycolab-metadata.json"] = len(payload)
            manifest_md5 = hashlib.md5(payload).hexdigest()
        for name, size in required.items():
            if os.path.getsize(os.path.join(self.directory, name)) != size:
                raise RuntimeError("模型文件大小发生变化，无法确认持久化。")
        with self.lock:
            self.required = required
            self.manifest_md5 = manifest_md5
            self.download_finished = True

    def finish(self, timeout=7200, heartbeat=None):
        if not self.drive:
            return True
        if not self.mount:
            return False
        self.prepare_confirmation()
        self.start()
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline and not self.stop_event.is_set():
            if self.verified_event.wait(1):
                return True
            if heartbeat:
                heartbeat()
        with self.lock:
            if self.upload_state != "error":
                self.upload_state = "error"
                self.message = "Drive 上传确认超时；本地文件保留，请勿释放实例，可点击校验权重重试。"
        self.cancel()
        return False

    def accept_remote(self, sizes, hashes, partial, dirty):
        with self.lock:
            confirmed = {name for name, size in self.required.items() if sizes.get(name) == size and name not in dirty}
            self.confirmed = sum(size for name, size in self.sizes.items() if name in confirmed)
            self.uploaded = self.confirmed + sum(min(self.sizes[name], max(0, int(value))) for name, value in partial.items() if name in self.sizes and name not in confirmed)
            self.checked_at = time.monotonic()
            metadata_matches = not self.manifest_md5 or hashes.get(".easycolab-metadata.json", "").lower() == self.manifest_md5
            if self.download_finished and len(confirmed) == len(self.required) and metadata_matches:
                self.upload_state = "verified"
                self.message = "Drive 远端权重大小与配置清单校验通过，已持久化。"
                self.verified_event.set()
            else:
                self.verified_event.clear()
                self.upload_state = "verifying" if self.download_finished else "uploading"
                self.message = "Drive 正在上传/校验；已发送字节不等于上传成功，请勿释放实例。"

    def _rc_stats(self):
        self.upload_live = False
        try:
            with open(RC_STATE_PATH, encoding="utf-8") as stream:
                config = json.load(stream)
            if config["source"] != self.mount["source"] or config["mount"] != self.mount["path"]:
                return {}, None
            if not re.fullmatch(r"http://127\.0\.0\.1:[0-9]+", config["url"]):
                return {}, None
            credentials = base64.b64encode((config["user"] + ":" + config["password"]).encode()).decode()
            opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))

            def request(method):
                query = urllib.request.Request(config["url"] + "/" + method, data=b"{}", headers={"Authorization": "Basic " + credentials, "Content-Type": "application/json"})
                with opener.open(query, timeout=5) as response:
                    return json.load(response)

            stats = request("core/stats")
            cache = request("vfs/stats").get("diskCache", {})
            self.upload_live = True
            prefix = self.mount["relative"].rstrip("/") + "/"
            partial = {item["name"][len(prefix):]: item.get("bytes", 0) for item in stats.get("transferring", []) if item.get("name", "").startswith(prefix)}
            return partial, cache.get("pathMeta")
        except (OSError, ValueError, KeyError, TypeError):
            return {}, None

    def _dirty_files(self, cache_path):
        if cache_path:
            folders = [os.path.join(cache_path, self.mount["relative"])]
        else:
            remote_name, root = self.mount.get("cache_source", self.mount["source"]).split(":", 1)
            folders = [os.path.join(os.path.expanduser("~/.cache/rclone/vfsMeta"), remote_name, root.lstrip("/"), self.mount["relative"])]
        dirty = set()
        for folder in folders:
            for name in self.required:
                path = os.path.join(folder, name)
                if not os.path.exists(path):
                    continue
                try:
                    with open(path, encoding="utf-8") as stream:
                        if json.load(stream).get("Dirty"):
                            dirty.add(name)
                except (OSError, ValueError):
                    dirty.add(name)
        return dirty

    def poll(self):
        if not os.path.ismount(self.mount["path"]):
            raise RuntimeError("Drive 挂载已断开；尚未确认持久化，请勿释放实例。")
        result = subprocess.run(
            ["rclone", "lsjson", self.mount["remote"], "--recursive", "--files-only", "--hash", "--retries", "1", "--low-level-retries", "1", "--contimeout", "10s", "--timeout", "20s"],
            capture_output=True, text=True, timeout=45,
        )
        if result.returncode:
            if "directory not found" in result.stderr.lower() and not self.download_finished:
                return
            raise RuntimeError("无法查询 Drive 远端文件，请检查授权、配额和网络；缓存不能算已持久化。")
        entries = json.loads(result.stdout)
        sizes = {item["Path"]: item["Size"] for item in entries if not item.get("IsDir")}
        hashes = {item["Path"]: item.get("Hashes", {}).get("md5", "") for item in entries}
        partial, cache_path = self._rc_stats()
        self.accept_remote(sizes, hashes, partial, self._dirty_files(cache_path))

    def _monitor(self):
        failures = 0
        while not self.stop_event.is_set():
            try:
                self.poll()
                failures = 0
            except Exception:
                failures += 1
                with self.lock:
                    self.verified_event.clear()
                    self.upload_state = "error"
                    self.message = "Drive 远端查询失败，尚未确认持久化；请检查挂载、授权、配额和网络。"
                if failures >= 3:
                    self.cancel()
                    return
            self.stop_event.wait(30 if self.verified_event.is_set() else 10)
