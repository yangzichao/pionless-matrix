#!/usr/bin/env python3
"""Send each trigger prompt to each host and record which skills it loads.

A run stops as soon as any skill loads, because only routing is measured.
Otherwise it stops when the host finishes or after the timeout.
Raw event logs go to the output directory, outside the repo.
"""

import argparse
import json
import os
import signal
import subprocess
import tempfile
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from pathlib import Path

from host_adapters import (
    SUPPORTED_HOSTS,
    final_text_in_event,
    host_command,
    host_version_command,
    model_in_event,
    skills_loaded_in_event,
)

PROBE_DIR = Path(__file__).resolve().parent
PROMPTS_FILE = PROBE_DIR / "trigger_prompts.json"
TIMEOUT_SECONDS = 240


def parse_arguments():
    default_output = Path(tempfile.gettempdir()) / "pionless-trigger-probe" / datetime.now().strftime("%Y-%m-%d-%H%M")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runs", type=int, default=3, help="runs per prompt per host (default 3)")
    parser.add_argument("--hosts", nargs="+", default=list(SUPPORTED_HOSTS), choices=SUPPORTED_HOSTS)
    parser.add_argument("--only", nargs="+", default=[], help="prompt ids to run (default all)")
    parser.add_argument("--output-dir", type=Path, default=default_output)
    parser.add_argument("--parallel", type=int, default=4)
    return parser.parse_args()


def kill_process_group(process):
    # macOS raises PermissionError once the group has already exited.
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except OSError:
        pass


def run_one(host, case, run_index, output_dir):
    neutral_cwd = output_dir / "cwd"
    raw_file = output_dir / "raw" / f"{host}--{case['id']}--run{run_index}.jsonl"
    started = time.time()
    process = subprocess.Popen(
        host_command(host, case["prompt"]), cwd=neutral_cwd, stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, start_new_session=True,
    )
    watchdog = threading.Timer(TIMEOUT_SECONDS + 10, lambda: kill_process_group(process))
    watchdog.start()
    skills_loaded, final_text, model, end_reason = [], "", None, "finished"
    with raw_file.open("w", encoding="utf-8") as raw:
        for line in process.stdout:
            raw.write(line)
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            model = model or model_in_event(host, event)
            final_text = final_text_in_event(host, event) or final_text
            for skill in skills_loaded_in_event(host, event):
                if skill not in skills_loaded:
                    skills_loaded.append(skill)
            if skills_loaded:
                end_reason = "skill-loaded"
                break
    watchdog.cancel()
    kill_process_group(process)
    process.wait()
    if end_reason == "finished" and time.time() - started > TIMEOUT_SECONDS:
        end_reason = "timeout"
    target_loaded = case["skill"] in skills_loaded
    return {
        "host": host, "model": model, "run": run_index, "id": case["id"], "skill": case["skill"],
        "expect": case["expect"], "skills_loaded": skills_loaded,
        "passed": target_loaded if case["expect"] == "trigger" else not target_loaded,
        "end_reason": end_reason, "seconds": round(time.time() - started),
        "final_text_head": final_text[:200],
    }


def write_run_meta(arguments):
    versions = {}
    for host in arguments.hosts:
        versions[host] = subprocess.run(host_version_command(host), capture_output=True, text=True).stdout.strip()
    meta = {"started": datetime.now().isoformat(timespec="minutes"), "runs": arguments.runs, "cli_versions": versions}
    (arguments.output_dir / "run-meta.json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")


def main():
    arguments = parse_arguments()
    (arguments.output_dir / "cwd").mkdir(parents=True, exist_ok=True)
    (arguments.output_dir / "raw").mkdir(exist_ok=True)
    write_run_meta(arguments)
    cases = json.loads(PROMPTS_FILE.read_text(encoding="utf-8"))
    jobs = [(host, case, run_index, arguments.output_dir)
            for run_index in range(1, arguments.runs + 1)
            for case in cases if not arguments.only or case["id"] in arguments.only
            for host in arguments.hosts]
    results_file = arguments.output_dir / "results.jsonl"
    print(f"writing to {arguments.output_dir}", flush=True)
    with ThreadPoolExecutor(max_workers=arguments.parallel) as pool, results_file.open("a", encoding="utf-8") as results:
        for result in pool.map(lambda job: run_one(*job), jobs):
            results.write(json.dumps(result, ensure_ascii=False) + "\n")
            results.flush()
            mark = "PASS" if result["passed"] else "FAIL"
            print(f"{mark} run{result['run']} {result['host']:<11} {result['id']:<16} "
                  f"loaded={result['skills_loaded']} ({result['end_reason']}, {result['seconds']}s)", flush=True)
    print(f"\nsummarize with: python3 {PROBE_DIR / 'summarize_results.py'} {results_file}")


if __name__ == "__main__":
    main()
