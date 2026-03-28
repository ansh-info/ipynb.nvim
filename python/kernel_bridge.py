#!/usr/bin/env python3
"""
kernel_bridge.py — Jupyter kernel ↔ Neovim JSON-line bridge.

Spawned by kernel.lua via vim.fn.jobstart().  Communicates with Neovim
over stdin/stdout using newline-delimited JSON (one JSON object per line).

Protocol
--------
Neovim → bridge (stdin):
    {"cmd": "start",    "kernel": "python3"}
    {"cmd": "attach",   "connection_file": "/path/kernel.json"}
    {"cmd": "execute",  "code": "...", "msg_id": "abc123"}
    {"cmd": "complete", "code": "...", "cursor_pos": 5,  "msg_id": "abc123"}
    {"cmd": "inspect",  "code": "...", "cursor_pos": 5,  "msg_id": "abc123"}
    {"cmd": "kernel_info"}
    {"cmd": "interrupt"}
    {"cmd": "shutdown"}

Bridge → Neovim (stdout):
    {"type": "status",        "state": "starting"|"idle"|"busy",   "msg_id": "..."}
    {"type": "stream",        "name": "stdout"|"stderr", "text":   "...", "msg_id": "..."}
    {"type": "result",        "text": "...", "html": "...",          "msg_id": "..."}
    {"type": "image",         "mime": "image/png", "data": "<b64>", "msg_id": "..."}
    {"type": "error",         "ename": "...", "evalue": "...",
                              "traceback": [...],                    "msg_id": "..."}
    {"type": "clear_output",                                         "msg_id": "..."}
    {"type": "complete",      "matches": [...], "cursor_start": 5,  "msg_id": "..."}
    {"type": "inspect",       "text": "...",                        "msg_id": "..."}
    {"type": "kernel_info",   "language": "python3", "version": "3.12", "msg_id": "..."}
    {"type": "execute_input", "code": "...", "exec_count": 1,       "msg_id": "..."}
    {"type": "error_internal","message": "..."}

msg_id mapping
--------------
Lua assigns its own opaque msg_ids.  jupyter_client assigns ZMQ msg_ids
internally.  This bridge maintains a pending_map {zmq_id: lua_id} so
every outgoing message carries the original Lua msg_id rather than the
raw ZMQ id.  This makes Lua-side tracking trivial.
"""

from __future__ import annotations

import json
import os
import queue
import re
import sys
import threading
import time
import traceback as tb_mod
from typing import Optional

from jupyter_client import KernelManager, find_connection_file
from jupyter_client.blocking import BlockingKernelClient

# ── stdout lock ────────────────────────────────────────────────────────────────
# All writes to stdout must hold this lock because the IOPub thread and
# the main stdin-reading thread both call send().
_stdout_lock = threading.Lock()

# ── ANSI escape strip ──────────────────────────────────────────────────────────
_ANSI_RE = re.compile(r"\x1b(?:\[[0-9;?]*[A-Za-z]|\][^\x07]*\x07|[()][0-9A-Z])")


def _strip_ansi(text: str) -> str:
    return _ANSI_RE.sub("", text)


def _venv_kernel_python() -> Optional[str]:
    """Return the Python from an active venv or conda env, if available.

    Checks $VIRTUAL_ENV and $CONDA_PREFIX.  Also verifies that ipykernel is
    installed in the venv - without it the kernel process cannot launch.
    If the venv is found but ipykernel is missing, emits an actionable error
    and returns None so the default kernel spec is used as fallback.
    """
    import subprocess as _sp

    for var in ("VIRTUAL_ENV", "CONDA_PREFIX"):
        prefix = os.environ.get(var)
        if not prefix:
            continue
        for rel in ("bin/python3", "bin/python"):
            path = os.path.join(prefix, rel)
            if not (os.path.isfile(path) and os.access(path, os.X_OK)):
                continue
            try:
                r = _sp.run([path, "-c", "import ipykernel"],
                            capture_output=True, timeout=5)
                if r.returncode == 0:
                    return path
            except Exception:
                pass
            # ipykernel missing - warn and fall back to default kernel spec.
            send({
                "type": "error_internal",
                "message": (
                    f"Venv detected ({prefix}) but ipykernel is not installed. "
                    "Run: uv pip install ipykernel  (or: pip install ipykernel). "
                    "Falling back to system Python kernel."
                ),
            })
            return None
    return None


def _get_shell_reply(zmq_id: str, timeout: float = 10.0) -> dict:
    """Fetch the shell reply whose parent msg_id matches zmq_id.

    In jupyter_client >= 8.x, KernelClient.complete() and .inspect() return
    the ZMQ msg_id (str) rather than the reply dict.  This helper polls
    get_shell_msg() until the matching reply arrives, discarding unrelated
    messages (e.g. execute_reply for a concurrently running cell).
    """
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            break
        try:
            reply = _kc.get_shell_msg(timeout=min(1.0, remaining))  # type: ignore[union-attr]
        except queue.Empty:
            break
        if reply.get("parent_header", {}).get("msg_id") == zmq_id:
            return reply.get("content", {})
    return {}


# ── Global kernel state ────────────────────────────────────────────────────────
_km: Optional[KernelManager] = None          # manages kernel process lifecycle
_kc: Optional[BlockingKernelClient] = None   # ZMQ channel client
_running = True                              # main loop sentinel
_iopub_thread: Optional[threading.Thread] = None

# Maps ZMQ parent msg_id → caller's Lua msg_id.
# Written by main thread (cmd_execute), read by IOPub thread.
# Protected by a simple dict (CPython GIL ensures atomic set/get).
_pending: dict[str, str] = {}


# ── Output helpers ─────────────────────────────────────────────────────────────

def send(msg: dict) -> None:
    """Write one JSON line to stdout (thread-safe)."""
    with _stdout_lock:
        sys.stdout.write(json.dumps(msg) + "\n")
        sys.stdout.flush()


def _lua_id(zmq_parent_id: str) -> str:
    """Translate a ZMQ parent msg_id to the originating Lua msg_id (or keep as-is)."""
    return _pending.get(zmq_parent_id, zmq_parent_id)


# ── IOPub listener (background thread) ────────────────────────────────────────

def _iopub_listener() -> None:
    """Continuously drain the IOPub channel and relay messages to Neovim."""
    global _running
    while _running:
        if _kc is None:
            time.sleep(0.05)
            continue
        try:
            msg = _kc.get_iopub_msg(timeout=0.1)
            _process_iopub(msg)
        except Exception:
            # TimeoutError / Empty from the queue is expected — just keep looping.
            # Any real error would repeatedly surface; silence it to avoid spam.
            pass


def _process_iopub(msg: dict) -> None:
    """Translate a single IOPub message into a JSON-line sent to Neovim."""
    msg_type = msg.get("header", {}).get("msg_type", "")
    content  = msg.get("content", {})
    zmq_pid  = msg.get("parent_header", {}).get("msg_id", "")
    lid      = _lua_id(zmq_pid)

    if msg_type == "status":
        state = content.get("execution_state", "")
        send({"type": "status", "state": state, "msg_id": lid})
        # Clean up pending map when the kernel goes back to idle.
        if state == "idle" and zmq_pid in _pending:
            del _pending[zmq_pid]

    elif msg_type == "stream":
        send({
            "type": "stream",
            "name": content.get("name", "stdout"),
            "text": _strip_ansi(content.get("text", "")),
            "msg_id": lid,
        })

    elif msg_type in ("execute_result", "display_data"):
        data = content.get("data", {})
        # Images take priority over plain text in the same message.
        if "image/png" in data:
            send({"type": "image", "mime": "image/png",
                  "data": data["image/png"], "msg_id": lid})
        if "image/jpeg" in data:
            send({"type": "image", "mime": "image/jpeg",
                  "data": data["image/jpeg"], "msg_id": lid})
        if "image/svg+xml" in data:
            send({"type": "image", "mime": "image/svg+xml",
                  "data": data["image/svg+xml"], "msg_id": lid})
        if "text/plain" in data:
            send({
                "type": "result",
                "text": _strip_ansi(data.get("text/plain", "")),
                "html": data.get("text/html", ""),
                "msg_id": lid,
            })

    elif msg_type == "error":
        raw_tb = content.get("traceback", [])
        clean_tb = [_strip_ansi(line) for line in raw_tb]
        send({
            "type":      "error",
            "ename":     content.get("ename", ""),
            "evalue":    _strip_ansi(content.get("evalue", "")),
            "traceback": clean_tb,
            "msg_id":    lid,
        })

    elif msg_type == "clear_output":
        send({"type": "clear_output", "msg_id": lid})

    elif msg_type == "execute_input":
        send({
            "type":       "execute_input",
            "code":       content.get("code", ""),
            "exec_count": content.get("execution_count"),
            "msg_id":     lid,
        })


# ── Command handlers ───────────────────────────────────────────────────────────

def _start_iopub_thread() -> None:
    global _iopub_thread
    if _iopub_thread is None or not _iopub_thread.is_alive():
        _iopub_thread = threading.Thread(target=_iopub_listener, daemon=True)
        _iopub_thread.start()


def cmd_start(data: dict) -> None:
    """Start a new kernel process (non-blocking — spawns a background thread)."""
    def _do_start() -> None:
        global _km, _kc
        kernel_name = data.get("kernel", "python3")
        try:
            km = KernelManager(kernel_name=kernel_name)
            venv_py = _venv_kernel_python()
            if venv_py:
                # Replace argv[0] (the Python executable) with the venv Python
                # so packages installed in the active venv are available.
                ks_argv = list(km.kernel_spec.argv)
                ks_argv[0] = venv_py
                km.kernel_cmd = ks_argv
            km.start_kernel()
            kc = km.blocking_client()
            kc.start_channels()
            kc.wait_for_ready(timeout=60)
            # Assign to globals only after fully ready (CPython GIL keeps this safe).
            _km = km
            _kc = kc
            send({"type": "status", "state": "starting", "msg_id": ""})
            _start_iopub_thread()
            _send_kernel_info_request()
        except Exception as exc:
            send({"type": "error_internal",
                  "message": f"Failed to start kernel '{kernel_name}': {exc}"})

    threading.Thread(target=_do_start, daemon=True).start()


def cmd_attach(data: dict) -> None:
    """Attach to an already-running kernel via its connection file."""
    global _kc
    cf = data.get("connection_file")
    try:
        if not cf:
            cf = find_connection_file()
        _kc = BlockingKernelClient(connection_file=cf)
        _kc.load_connection_file()
        _kc.start_channels()
        _kc.wait_for_ready(timeout=30)
        send({"type": "status", "state": "idle", "msg_id": ""})
        _start_iopub_thread()
        _send_kernel_info_request()
    except Exception as exc:
        send({"type": "error_internal",
              "message": f"Failed to attach to kernel: {exc}"})


def _send_kernel_info_request() -> None:
    """Request kernel_info_reply and emit a kernel_info message."""
    if _kc is None:
        return
    try:
        reply = _kc.kernel_info()
        info  = reply.get("content", {})
        lang  = info.get("language_info", {}).get("name", "")
        ver   = info.get("language_info", {}).get("version", "")
        send({"type": "kernel_info", "language": lang, "version": ver, "msg_id": ""})
    except Exception:
        pass


def cmd_kernel_info(_data: dict) -> None:
    _send_kernel_info_request()


def cmd_execute(data: dict) -> None:
    """Send an execute_request to the kernel."""
    if _kc is None:
        send({"type": "error_internal", "message": "No kernel connected. Run :IpynbKernelStart first."})
        return
    code   = data.get("code", "")
    lua_id = data.get("msg_id", "")
    try:
        zmq_id = _kc.execute(code, store_history=True)
        # Register the ZMQ → Lua mapping so the IOPub thread can translate.
        _pending[zmq_id] = lua_id
    except Exception as exc:
        send({"type": "error_internal", "message": f"Execute failed: {exc}"})


def cmd_complete(data: dict) -> None:
    if _kc is None:
        send({"type": "error_internal", "message": "No kernel connected."})
        return
    code       = data.get("code", "")
    cursor_pos = data.get("cursor_pos", len(code))
    lua_id     = data.get("msg_id", "")
    try:
        zmq_id  = _kc.complete(code, cursor_pos)
        content = _get_shell_reply(zmq_id)
        send({
            "type":         "complete",
            "matches":      content.get("matches", []),
            "cursor_start": content.get("cursor_start", cursor_pos),
            "cursor_end":   content.get("cursor_end",   cursor_pos),
            "msg_id":       lua_id,
        })
    except Exception as exc:
        send({"type": "error_internal", "message": f"Complete failed: {exc}"})


def cmd_inspect(data: dict) -> None:
    if _kc is None:
        send({"type": "error_internal", "message": "No kernel connected."})
        return
    code       = data.get("code", "")
    cursor_pos = data.get("cursor_pos", len(code))
    lua_id     = data.get("msg_id", "")
    try:
        zmq_id   = _kc.inspect(code, cursor_pos)
        content  = _get_shell_reply(zmq_id)
        raw_text = content.get("data", {}).get("text/plain", "")
        send({"type": "inspect", "text": _strip_ansi(raw_text), "msg_id": lua_id})
    except Exception as exc:
        send({"type": "error_internal", "message": f"Inspect failed: {exc}"})


def cmd_interrupt(_data: dict) -> None:
    if _km is not None:
        try:
            _km.interrupt_kernel()
        except Exception as exc:
            send({"type": "error_internal", "message": f"Interrupt failed: {exc}"})
    else:
        send({"type": "error_internal", "message": "No kernel manager (cannot interrupt attached kernel)."})


def cmd_shutdown(_data: dict) -> None:
    global _running
    _running = False
    if _km is not None:
        try:
            _km.shutdown_kernel(now=True)
        except Exception:
            pass
    if _kc is not None:
        try:
            _kc.stop_channels()
        except Exception:
            pass


# ── Dispatch table ─────────────────────────────────────────────────────────────

_HANDLERS: dict = {
    "start":       cmd_start,
    "attach":      cmd_attach,
    "execute":     cmd_execute,
    "complete":    cmd_complete,
    "inspect":     cmd_inspect,
    "kernel_info": cmd_kernel_info,
    "interrupt":   cmd_interrupt,
    "shutdown":    cmd_shutdown,
}


# ── Main loop ──────────────────────────────────────────────────────────────────

def main() -> None:
    for raw_line in sys.stdin:
        if not _running:
            break
        line = raw_line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError as exc:
            send({"type": "error_internal", "message": f"JSON parse error: {exc}"})
            continue

        cmd = msg.get("cmd", "")
        handler = _HANDLERS.get(cmd)
        if handler:
            try:
                handler(msg)
            except Exception:
                send({"type": "error_internal",
                      "message": f"Unhandled error in [{cmd}]:\n{tb_mod.format_exc()}"})
        else:
            send({"type": "error_internal", "message": f"Unknown command: {cmd!r}"})


if __name__ == "__main__":
    main()
