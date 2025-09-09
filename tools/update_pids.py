#!/usr/bin/env python3
"""
Sync PIDs from docs/PIDs.md into:
 - contracts/scripts/configure-integration.lua (PROCESS_IDS)
 - contracts/scripts/verify-e2e.lua (P table)
 - contracts/verify/verify-test-processes.lua (TEST_PROCESSES)

Usage:
  python3 tools/update_pids.py [--env TEST|PROD]

Defaults to TEST.
"""
from __future__ import annotations
import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PIDS_MD = ROOT / "docs" / "PIDs.md"

FILES = {
    "configure": ROOT / "contracts" / "scripts" / "configure-integration.lua",
    "e2e": ROOT / "contracts" / "scripts" / "verify-e2e.lua",
    "verify": ROOT / "contracts" / "verify" / "verify-test-processes.lua",
}

def parse_pids(env: str) -> dict:
    text = PIDS_MD.read_text()
    # Find section header
    header = f"## {env.upper()}"
    if env.upper() == "TEST":
        header = "## TEST (development)"
    start = text.find(header)
    if start == -1:
        raise SystemExit(f"Could not find section header '{header}' in {PIDS_MD}")
    end = text.find("\n## ", start + 1)
    section = text[start:end] if end != -1 else text[start:]
    # Extract simple "Name: PID" lines
    pid_map = {}
    for line in section.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith("##"):
            continue
        if ":" in line:
            k, v = line.split(":", 1)
            pid = v.strip().split()[0] if v.strip() else ""
            key = k.strip()
            if pid:
                pid_map[key] = pid
    # Normalize keys we care about
    norm = {
        "COORDINATOR": pid_map.get("Coordinator", ""),
        "LOCK_MANAGER": pid_map.get("Lock Manager", ""),
        "TOKEN_MANAGER": pid_map.get("Token Manager", ""),
        "STATE_MANAGER": pid_map.get("State Manager", ""),
        "MOCK_USDA": pid_map.get("Mock USDA", "") or pid_map.get("USDA (real)", ""),
    }
    missing = [k for k, v in norm.items() if not v]
    if missing:
        print(f"Warning: missing PIDs for {missing}; will skip those updates.")
    return norm

def update_file_configure(pids: dict):
    path = FILES["configure"]
    s = path.read_text()
    for key in ("MOCK_USDA", "COORDINATOR", "STATE_MANAGER", "LOCK_MANAGER", "TOKEN_MANAGER"):
        if not pids.get(key):
            continue
        s = re.sub(
            rf"(\\b{key}\\s*=\\s*\")(.*?)(\")",
            rf"\\1{pids[key]}\\3",
            s,
            flags=re.MULTILINE,
        )
    path.write_text(s)
    print(f"Updated: {path.relative_to(ROOT)}")

def update_file_e2e(pids: dict):
    path = FILES["e2e"]
    s = path.read_text()
    for key in ("COORDINATOR", "LOCK_MANAGER", "TOKEN_MANAGER", "STATE_MANAGER", "MOCK_USDA"):
        if not pids.get(key):
            continue
        s = re.sub(
            rf"(\\b{key}\\s*=\\s*\")(.*?)(\")",
            rf"\\1{pids[key]}\\3",
            s,
            flags=re.MULTILINE,
        )
    path.write_text(s)
    print(f"Updated: {path.relative_to(ROOT)}")

def update_file_verify(pids: dict):
    path = FILES["verify"]
    s = path.read_text()
    mapping = {
        "coordinator": pids.get("COORDINATOR", ""),
        "lockManager": pids.get("LOCK_MANAGER", ""),
        "tokenManager": pids.get("TOKEN_MANAGER", ""),
        "stateManager": pids.get("STATE_MANAGER", ""),
    }
    for key, pid in mapping.items():
        if not pid:
            continue
        s = re.sub(
            rf"(\\b{key}\\s*=\\s*\")(.*?)(\")",
            rf"\\1{pid}\\3",
            s,
            flags=re.MULTILINE,
        )
    path.write_text(s)
    print(f"Updated: {path.relative_to(ROOT)}")

def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--env", choices=["TEST", "PROD"], default="TEST")
    args = ap.parse_args()
    pids = parse_pids(args.env)
    update_file_configure(pids)
    update_file_e2e(pids)
    update_file_verify(pids)
    print("Done. Review changes with 'git diff' and commit.")

if __name__ == "__main__":
    main()
