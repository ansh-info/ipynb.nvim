#!/usr/bin/env python3
"""
kernel_bridge.py — Jupyter kernel ↔ Neovim JSON-line bridge.

This script is spawned by jupytervim (lua/jupytervim/kernel.lua) as a
background job via vim.fn.jobstart().  It communicates with Neovim over
stdin/stdout using newline-delimited JSON messages.

Protocol
--------
Neovim → bridge (stdin):
    {"cmd": "start",     "kernel": "python3"}
    {"cmd": "attach",    "connection_file": "/path/kernel.json"}
    {"cmd": "execute",   "code": "...", "msg_id": "abc123"}
    {"cmd": "complete",  "code": "...", "cursor_pos": 5, "msg_id": "abc123"}
    {"cmd": "inspect",   "code": "...", "cursor_pos": 5, "msg_id": "abc123"}
    {"cmd": "interrupt"}
    {"cmd": "shutdown"}

Bridge → Neovim (stdout):
    {"type": "stream",     "name": "stdout"|"stderr", "text": "...",    "msg_id": "..."}
    {"type": "result",     "text": "...", "html": "...",                "msg_id": "..."}
    {"type": "image",      "mime": "image/png", "data": "<b64>",        "msg_id": "..."}
    {"type": "error",      "ename": "...", "evalue": "...",
                           "traceback": [...],                           "msg_id": "..."}
    {"type": "status",     "state": "busy"|"idle"|"starting",           "msg_id": "..."}
    {"type": "complete",   "matches": [...], "cursor_start": 5,         "msg_id": "..."}
    {"type": "inspect",    "text": "...",                               "msg_id": "..."}
    {"type": "kernel_info","language": "python3", "version": "3.11",   "msg_id": "..."}
    {"type": "error_internal", "message": "..."}

Status
------
Phase 1: This file is a documented stub — the kernel communication logic
         will be implemented in Phase 2.  The bridge process exits cleanly
         if invoked, printing an info message to stderr.
"""

import sys
import json


def send(msg: dict) -> None:
    """Write a JSON-line message to stdout."""
    print(json.dumps(msg), flush=True)


def main() -> None:
    send({
        "type": "error_internal",
        "message": (
            "kernel_bridge.py: Phase 2 not yet implemented. "
            "Kernel execution will be available after Phase 2."
        ),
    })
    # Wait for a shutdown command so the Neovim job doesn't exit immediately
    # and produce spurious 'job exited' messages.
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            continue
        if msg.get("cmd") == "shutdown":
            break
    sys.exit(0)


if __name__ == "__main__":
    main()
