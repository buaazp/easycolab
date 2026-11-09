"""Bounded, read-only host and process telemetry without command lines or environments."""

import copy
import csv
import io
import os
from pathlib import Path
import subprocess
import threading
import time


def percentage(value):
    try:
        return max(0.0, min(100.0, float(value)))
    except (ValueError, TypeError):
        return None


class ResourceMonitor:
    def __init__(self, proc_root="/proc"):
        self.root = Path(proc_root)
        self.lock = threading.Lock()
        self.previous_cpu = None
        self.previous_processes = {}
        self.process_time = None
        self.process_lease = 0.0
        self.cached = {"sampled_at": None, "cpu_utilization_pct": None, "cpu_count": os.cpu_count() or 1,
                       "gpu_utilization_pct": None, "gpus": [], "processes": [], "gpu_processes": [],
                       "process_sampled_at": None, "process_total": 0, "truncated": False}

    def _run(self, args):
        try:
            result = subprocess.run(args, capture_output=True, text=True, timeout=3)
            return result.stdout if result.returncode == 0 else ""
        except (OSError, subprocess.TimeoutExpired):
            return ""

    def _cpu(self):
        fields = (self.root / "stat").read_text().splitlines()[0].split()[1:9]
        values = [int(value) for value in fields]
        current = (sum(values), values[3] + (values[4] if len(values) > 4 else 0))
        previous, self.previous_cpu = self.previous_cpu, current
        if previous is None or current[0] <= previous[0]:
            return None
        return percentage(100 * (1 - (current[1] - previous[1]) / (current[0] - previous[0])))

    def _gpus(self):
        output = self._run(["nvidia-smi", "--query-gpu=index,name,utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu,power.draw", "--format=csv,noheader,nounits"])
        rows = []
        for fields in csv.reader(io.StringIO(output)):
            if len(fields) != 8:
                continue
            try:
                def number(value):
                    try:
                        return float(value.strip())
                    except ValueError:
                        return None
                rows.append({"index": int(fields[0]), "name": fields[1].strip()[:120],
                             "utilization_pct": percentage(fields[2]), "memory_utilization_pct": percentage(fields[3]),
                             "memory_used_mib": number(fields[4]), "memory_total_mib": number(fields[5]),
                             "temperature_c": number(fields[6]), "power_w": number(fields[7])})
            except ValueError:
                continue
        return rows

    def _processes(self):
        now = time.monotonic()
        elapsed = now - self.process_time if self.process_time is not None else 0
        ticks = os.sysconf("SC_CLK_TCK")
        page_size = os.sysconf("SC_PAGE_SIZE")
        current, rows = {}, []
        for path in self.root.iterdir():
            if not path.name.isdigit():
                continue
            try:
                raw = (path / "stat").read_text()
                name, rest = raw.split("(", 1)[1].rsplit(")", 1)
                fields = rest.split()
                key = (int(path.name), fields[19])
                used = int(fields[11]) + int(fields[12])
                previous = self.previous_processes.get(key)
                cpu = round(max(0, used - previous) / ticks / elapsed * 100, 1) if previous is not None and elapsed > 0 else None
                current[key] = used
                rows.append({"pid": key[0], "name": name[:80], "state": fields[0], "cpu_pct": cpu,
                             "rss_mib": round(int(fields[21]) * page_size / 1024**2, 1), "threads": int(fields[17])})
            except (OSError, ValueError, IndexError):
                continue
        self.previous_processes, self.process_time = current, now
        rows.sort(key=lambda row: (row["cpu_pct"] or 0, row["rss_mib"]), reverse=True)
        return rows

    def _gpu_processes(self, processes):
        names = {row["pid"]: row["name"] for row in processes}
        output = self._run(["nvidia-smi", "--query-compute-apps=pid,used_gpu_memory,gpu_uuid", "--format=csv,noheader,nounits"])
        rows = []
        utilization = {}
        for line in self._run(["nvidia-smi", "pmon", "-c", "1", "-s", "um"]).splitlines():
            fields = line.split()
            if len(fields) >= 5 and fields[0].isdigit() and fields[1].isdigit():
                utilization[int(fields[1])] = percentage(fields[3])
        for fields in csv.reader(io.StringIO(output)):
            try:
                if len(fields) != 3:
                    continue
                pid = int(fields[0])
                try:
                    memory = float(fields[1])
                except ValueError:
                    memory = None
                rows.append({"pid": pid, "name": names.get(pid, "unavailable"), "memory_mib": memory,
                             "gpu_uuid": fields[2].strip()[:96], "gpu_pct": utilization.get(pid)})
            except ValueError:
                continue
        return sorted(rows, key=lambda row: row["memory_mib"] or 0, reverse=True)[:200]

    def sample(self):
        try:
            cpu = self._cpu()
        except (OSError, ValueError, IndexError):
            cpu = None
        gpus = self._gpus()
        updates = {"sampled_at": time.time(), "cpu_utilization_pct": cpu,
                   "gpu_utilization_pct": gpus[0]["utilization_pct"] if gpus else None, "gpus": gpus}
        with self.lock:
            details_requested = time.monotonic() < self.process_lease
        if details_requested:
            try:
                processes = self._processes()
                updates.update(processes=processes[:200], gpu_processes=self._gpu_processes(processes),
                               process_total=len(processes), truncated=len(processes) > 200, process_sampled_at=time.time())
            except OSError:
                updates.update(processes=[], gpu_processes=[], process_sampled_at=None)
        with self.lock:
            self.cached.update(updates)
        return self.summary()

    def summary(self):
        with self.lock:
            return {key: self.cached[key] for key in ("sampled_at", "cpu_utilization_pct", "cpu_count", "gpu_utilization_pct")}

    def details(self):
        with self.lock:
            if self.cached["process_sampled_at"] is not None and time.time() - self.cached["process_sampled_at"] > 15:
                self.cached.update(processes=[], gpu_processes=[], process_sampled_at=None)
            self.process_lease = time.monotonic() + 15
            return copy.deepcopy(self.cached)


MONITOR = ResourceMonitor()
