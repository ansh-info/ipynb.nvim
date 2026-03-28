-- Headless Neovim test suite for ipynb.nvim
-- Run from the repo root:
--   nvim --headless -u NONE -c "set rtp+=/home/oneai/jupytervim" \
--     -l test/headless_test.lua

local pass = 0
local fail = 0

local function ok(label)
  pass = pass + 1
  print("PASS: " .. label)
end

local function fail_test(label, reason)
  fail = fail + 1
  print("FAIL: " .. label .. " -- " .. tostring(reason))
end

local function check(label, cond, reason)
  if cond then ok(label) else fail_test(label, reason or "assertion failed") end
end

-- ── 1. Module loading ─────────────────────────────────────────────────────────

local ok_kernel, kernel   = pcall(require, "ipynb.kernel")
local ok_insp,  inspector = pcall(require, "ipynb.inspector")
local ok_cell,  cell      = pcall(require, "ipynb.cell")

check("kernel.lua loads",    ok_kernel,   tostring(kernel))
check("inspector.lua loads", ok_insp,     tostring(inspector))
check("cell.lua loads",      ok_cell,     tostring(cell))

-- ── 2. execute_snippet API ────────────────────────────────────────────────────

check(
  "kernel.execute_snippet is a function",
  ok_kernel and type(kernel.execute_snippet) == "function",
  "execute_snippet missing"
)

-- ── 3. inspector.lua uses execute_snippet, no old monkey-patch ───────────────

local f = io.open("/home/oneai/jupytervim/lua/ipynb/inspector.lua", "r")
local insp_src = f:read("*all"); f:close()

check("inspector.lua calls execute_snippet",
  insp_src:find("execute_snippet") ~= nil)
check("inspector.lua has no output.append monkey-patch",
  insp_src:find("output%.append%s*=") == nil,
  "found 'output.append =' in inspector.lua")
check("inspector.lua has no vim.wait blocking call",
  insp_src:find("vim%.wait") == nil,
  "found vim.wait in inspector.lua")

-- ── 4. inspector.lua: no %-*s dynamic-width format ───────────────────────────

-- plain=true for literal string search (no Lua pattern special chars)
check("inspector.lua has no '%-*s' format spec",
  insp_src:find("%-*s", 1, true) == nil,
  "found '%-*s' in inspector.lua (unsupported in LuaJIT)")

-- Verify the format string actually works (would throw on macOS with %-*s)
local ok_fmt, err_fmt = pcall(function()
  local w = 20
  return string.format("  %-" .. w .. "s", "test")
end)
check("computed format string works in LuaJIT",
  ok_fmt, tostring(err_fmt))

-- ── 5. run_current_cell skips markdown cells ─────────────────────────────────

if ok_kernel and ok_cell then
  local orig_at_cursor = cell.cell_at_cursor
  cell.cell_at_cursor = function(_) return { cell_type = "markdown", start_mark = 1, end_mark = 2, index = 1 }, 1 end

  local utils = require("ipynb.utils")
  local captured = nil
  local orig_info = utils.info
  utils.info = function(msg) captured = msg end

  kernel.run_current_cell(0)

  cell.cell_at_cursor = orig_at_cursor
  utils.info = orig_info

  check("run_current_cell skips markdown cells",
    captured ~= nil and captured:find("Not a code cell") ~= nil,
    "expected 'Not a code cell', got: " .. tostring(captured))
else
  fail_test("run_current_cell markdown skip", "module load failed")
end

-- ── 6. kernel_bridge.py: _setup_ids race condition fix ───────────────────────

local g = io.open("/home/oneai/jupytervim/python/kernel_bridge.py", "r")
local bridge_src = g:read("*all"); g:close()

check("kernel_bridge.py has _setup_ids",
  bridge_src:find("_setup_ids") ~= nil)
check("kernel_bridge.py waits for setup reply before notifying Lua",
  bridge_src:find("_get_shell_reply%(setup_id") ~= nil,
  "_get_shell_reply(setup_id) not found - race condition fix missing")
check("kernel_bridge.py sends status:starting AFTER setup completes",
  -- The send(status:starting) must appear after _get_shell_reply in source
  (function()
    local setup_pos  = bridge_src:find("_get_shell_reply%(setup_id")
    local notify_pos = bridge_src:find('send.*"starting"', setup_pos or 1)
    return setup_pos ~= nil and notify_pos ~= nil and notify_pos > setup_pos
  end)(),
  "status:starting is sent before setup completes")

-- ── Summary ───────────────────────────────────────────────────────────────────

print(string.format("\n%d passed, %d failed", pass, fail))
vim.cmd(fail > 0 and "cq" or "quit")
