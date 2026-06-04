"""Unit tests for kernel_bridge.py pure functions."""

from __future__ import annotations

import io
import json
import os
import sys
from unittest.mock import patch

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from kernel_bridge import (
    _HANDLERS,
    _strip_ansi,
    _strip_ansi_controls,
    send,
)


class TestStripAnsi:
    """Tests for _strip_ansi - removes ALL ANSI escapes including SGR."""

    def test_plain_text_unchanged(self) -> None:
        assert _strip_ansi("hello world") == "hello world"

    def test_empty_string(self) -> None:
        assert _strip_ansi("") == ""

    def test_strips_sgr_color(self) -> None:
        assert _strip_ansi("\x1b[31mred\x1b[0m") == "red"

    def test_strips_bold_italic(self) -> None:
        assert _strip_ansi("\x1b[1mbold\x1b[22m \x1b[3mitalic\x1b[23m") == "bold italic"

    def test_strips_256_color(self) -> None:
        assert _strip_ansi("\x1b[38;5;196mred256\x1b[0m") == "red256"

    def test_strips_truecolor(self) -> None:
        assert _strip_ansi("\x1b[38;2;255;0;0mtrue\x1b[0m") == "true"

    def test_strips_cursor_movement(self) -> None:
        assert _strip_ansi("\x1b[2Amoved up") == "moved up"

    def test_strips_osc_sequences(self) -> None:
        assert _strip_ansi("\x1b]0;title\x07text") == "text"

    def test_strips_charset_selectors(self) -> None:
        assert _strip_ansi("\x1b(Btext\x1b(0") == "text"

    def test_mixed_escapes(self) -> None:
        text = "\x1b[1m\x1b[31mERROR\x1b[0m: \x1b[2Kfailed"
        assert _strip_ansi(text) == "ERROR: failed"

    def test_multiline(self) -> None:
        text = "\x1b[32mline1\x1b[0m\nline2\n\x1b[33mline3\x1b[0m"
        assert _strip_ansi(text) == "line1\nline2\nline3"


class TestStripAnsiControls:
    """Tests for _strip_ansi_controls - removes non-SGR escapes, preserves SGR."""

    def test_plain_text_unchanged(self) -> None:
        assert _strip_ansi_controls("hello world") == "hello world"

    def test_empty_string(self) -> None:
        assert _strip_ansi_controls("") == ""

    def test_preserves_sgr_color(self) -> None:
        text = "\x1b[31mred\x1b[0m"
        assert _strip_ansi_controls(text) == text

    def test_preserves_bold(self) -> None:
        text = "\x1b[1mbold\x1b[22m"
        assert _strip_ansi_controls(text) == text

    def test_preserves_256_color(self) -> None:
        text = "\x1b[38;5;196mcolored\x1b[0m"
        assert _strip_ansi_controls(text) == text

    def test_preserves_truecolor(self) -> None:
        text = "\x1b[38;2;255;128;0morange\x1b[0m"
        assert _strip_ansi_controls(text) == text

    def test_strips_cursor_up(self) -> None:
        assert _strip_ansi_controls("\x1b[2Atext") == "text"

    def test_strips_cursor_down(self) -> None:
        assert _strip_ansi_controls("\x1b[3Btext") == "text"

    def test_strips_cursor_forward(self) -> None:
        assert _strip_ansi_controls("\x1b[5Ctext") == "text"

    def test_strips_cursor_back(self) -> None:
        assert _strip_ansi_controls("\x1b[1Dtext") == "text"

    def test_strips_erase_line(self) -> None:
        assert _strip_ansi_controls("\x1b[2Ktext") == "text"

    def test_strips_erase_display(self) -> None:
        assert _strip_ansi_controls("\x1b[2Jtext") == "text"

    def test_strips_osc(self) -> None:
        assert _strip_ansi_controls("\x1b]0;title\x07text") == "text"

    def test_strips_charset(self) -> None:
        assert _strip_ansi_controls("\x1b(Btext") == "text"

    def test_strips_carriage_return(self) -> None:
        assert _strip_ansi_controls("progress\r100%") == "progress100%"

    def test_mixed_sgr_preserved_controls_stripped(self) -> None:
        text = "\x1b[31m\x1b[2Kerror\x1b[0m\roverwrite"
        expected = "\x1b[31merror\x1b[0moverwrite"
        assert _strip_ansi_controls(text) == expected

    def test_tqdm_style_progress(self) -> None:
        text = "50%|#####     | 5/10\r100%|##########| 10/10"
        expected = "50%|#####     | 5/10100%|##########| 10/10"
        assert _strip_ansi_controls(text) == expected


class TestSend:
    """Tests for the send() function - JSON-line output to stdout."""

    def test_sends_json_line(self) -> None:
        buf = io.StringIO()
        with patch("kernel_bridge.sys.stdout", buf):
            send({"type": "status", "state": "idle"})
        output = buf.getvalue()
        assert output.endswith("\n")
        parsed = json.loads(output.strip())
        assert parsed == {"type": "status", "state": "idle"}

    def test_sends_complex_message(self) -> None:
        buf = io.StringIO()
        msg = {
            "type": "error",
            "ename": "ZeroDivisionError",
            "evalue": "division by zero",
            "traceback": ["line 1", "line 2"],
            "msg_id": "abc123",
        }
        with patch("kernel_bridge.sys.stdout", buf):
            send(msg)
        parsed = json.loads(buf.getvalue().strip())
        assert parsed == msg

    def test_handles_unicode(self) -> None:
        buf = io.StringIO()
        with patch("kernel_bridge.sys.stdout", buf):
            send({"type": "stream", "text": "hello"})
        parsed = json.loads(buf.getvalue().strip())
        assert parsed["text"] == "hello"

    def test_multiple_sends_separate_lines(self) -> None:
        buf = io.StringIO()
        with patch("kernel_bridge.sys.stdout", buf):
            send({"type": "status", "state": "busy"})
            send({"type": "status", "state": "idle"})
        lines = buf.getvalue().strip().split("\n")
        assert len(lines) == 2
        assert json.loads(lines[0])["state"] == "busy"
        assert json.loads(lines[1])["state"] == "idle"


class TestHandlersDispatch:
    """Tests for the _HANDLERS dispatch table."""

    def test_all_commands_registered(self) -> None:
        expected_commands = {
            "start",
            "attach",
            "execute",
            "complete",
            "inspect",
            "kernel_info",
            "interrupt",
            "shutdown",
        }
        assert set(_HANDLERS.keys()) == expected_commands

    def test_handlers_are_callable(self) -> None:
        for cmd, handler in _HANDLERS.items():
            assert callable(handler), f"Handler for '{cmd}' is not callable"

    def test_unknown_command_not_in_table(self) -> None:
        assert _HANDLERS.get("nonexistent") is None

    def test_execute_without_kernel_sends_error(self) -> None:
        import kernel_bridge

        buf = io.StringIO()
        old_kc = kernel_bridge._kc
        kernel_bridge._kc = None
        try:
            with patch("kernel_bridge.sys.stdout", buf):
                _HANDLERS["execute"]({"code": "1+1", "msg_id": "test1"})
            parsed = json.loads(buf.getvalue().strip())
            assert parsed["type"] == "error_internal"
            assert "No kernel" in parsed["message"]
        finally:
            kernel_bridge._kc = old_kc

    def test_complete_without_kernel_sends_error(self) -> None:
        import kernel_bridge

        buf = io.StringIO()
        old_kc = kernel_bridge._kc
        kernel_bridge._kc = None
        try:
            with patch("kernel_bridge.sys.stdout", buf):
                _HANDLERS["complete"]({"code": "os.pa", "cursor_pos": 5, "msg_id": "t2"})
            parsed = json.loads(buf.getvalue().strip())
            assert parsed["type"] == "error_internal"
            assert "No kernel" in parsed["message"]
        finally:
            kernel_bridge._kc = old_kc

    def test_inspect_without_kernel_sends_error(self) -> None:
        import kernel_bridge

        buf = io.StringIO()
        old_kc = kernel_bridge._kc
        kernel_bridge._kc = None
        try:
            with patch("kernel_bridge.sys.stdout", buf):
                _HANDLERS["inspect"]({"code": "print", "cursor_pos": 5, "msg_id": "t3"})
            parsed = json.loads(buf.getvalue().strip())
            assert parsed["type"] == "error_internal"
            assert "No kernel" in parsed["message"]
        finally:
            kernel_bridge._kc = old_kc

    def test_interrupt_without_kernel_sends_error(self) -> None:
        import kernel_bridge

        buf = io.StringIO()
        old_km = kernel_bridge._km
        old_kc = kernel_bridge._kc
        kernel_bridge._km = None
        kernel_bridge._kc = None
        try:
            with patch("kernel_bridge.sys.stdout", buf):
                _HANDLERS["interrupt"]({})
            parsed = json.loads(buf.getvalue().strip())
            assert parsed["type"] == "error_internal"
            assert "No kernel" in parsed["message"]
        finally:
            kernel_bridge._km = old_km
            kernel_bridge._kc = old_kc


class TestVenvKernelPython:
    """Tests for _venv_kernel_python - venv/conda Python detection."""

    def test_returns_none_when_no_env_vars(self) -> None:
        from kernel_bridge import _venv_kernel_python

        with patch.dict(os.environ, {}, clear=True):
            env = os.environ.copy()
            env.pop("VIRTUAL_ENV", None)
            env.pop("CONDA_PREFIX", None)
            with patch.dict(os.environ, env, clear=True):
                result = _venv_kernel_python()
        assert result is None

    def test_returns_none_when_venv_path_missing(self) -> None:
        from kernel_bridge import _venv_kernel_python

        with patch.dict(os.environ, {"VIRTUAL_ENV": "/nonexistent/path"}, clear=True):
            result = _venv_kernel_python()
        assert result is None

    def test_returns_none_when_conda_path_missing(self) -> None:
        from kernel_bridge import _venv_kernel_python

        with patch.dict(os.environ, {"CONDA_PREFIX": "/nonexistent/conda"}, clear=True):
            result = _venv_kernel_python()
        assert result is None
