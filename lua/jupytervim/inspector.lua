--- jupytervim.inspector
--- Variable inspector: executes a Python snippet in the kernel to retrieve
--- all user-defined variables and displays them in a floating window.
---
--- Invoked via:
---   :JupyterInspect          — show variable inspector
---   <leader>ji               — keymap (registered by keymaps.lua)
---   require("jupytervim.inspector").open(bufnr)
---
--- The inspector window shows:
---   Name       Type        Value (truncated)
---   ─────────────────────────────────────────
---   x          int         42
---   df         DataFrame   <10 rows × 3 cols>
---   model      Sequential  <keras Model>
---
--- For the selected variable, pressing <CR> runs a deeper inspect
--- (calls kernel.inspect() at the variable name) and shows the docstring.

local M = {}

-- ── Introspection code executed inside the kernel ─────────────────────────────

-- Returns a JSON object: { varname: { type, repr, shape? } }
-- We use a private prefix to avoid polluting the namespace.
local INTROSPECT_CODE = [[
import json as __jvim_json
__jvim_vars = {}
for __jvim_name in sorted(dir()):
    if __jvim_name.startswith('_') or __jvim_name.startswith('__jvim'):
        continue
    try:
        __jvim_val  = eval(__jvim_name)
        __jvim_type = type(__jvim_val).__name__
        __jvim_repr = repr(__jvim_val)[:100]
        __jvim_entry = {'type': __jvim_type, 'repr': __jvim_repr}
        # Attach shape for numpy/pandas objects if available.
        if hasattr(__jvim_val, 'shape'):
            try:
                __jvim_entry['shape'] = str(tuple(__jvim_val.shape))
            except Exception:
                pass
        elif hasattr(__jvim_val, '__len__'):
            try:
                __jvim_entry['len'] = len(__jvim_val)
            except Exception:
                pass
        __jvim_vars[__jvim_name] = __jvim_entry
    except Exception:
        pass
print(__jvim_json.dumps(__jvim_vars))
del __jvim_json, __jvim_vars, __jvim_name, __jvim_val, __jvim_type, __jvim_repr, __jvim_entry
]]

-- ── Highlight groups ──────────────────────────────────────────────────────────

local _hl_done = false
local function define_highlights()
  if _hl_done then return end
  _hl_done = true
  vim.api.nvim_set_hl(0, "JupyterInspectorHeader", { fg = "#7aa2f7", bold = true })
  vim.api.nvim_set_hl(0, "JupyterInspectorName",   { fg = "#c0caf5"              })
  vim.api.nvim_set_hl(0, "JupyterInspectorType",   { fg = "#e0af68", italic = true })
  vim.api.nvim_set_hl(0, "JupyterInspectorValue",  { fg = "#9ece6a"              })
  vim.api.nvim_set_hl(0, "JupyterInspectorBorder", { fg = "#3b4261"              })
end

-- ── Result parsing ────────────────────────────────────────────────────────────

--- Extract the first JSON object from mixed stdout text.
---@param text string
---@return table|nil
local function parse_json_from_output(text)
  -- The kernel may print warnings before our JSON line; find the first { ... }
  local s, e = text:find("{.-}", 1, false)
  -- Try a greedy match for the full JSON object.
  for i = 1, #text do
    if text:sub(i, i) == "{" then
      local ok, result = pcall(vim.fn.json_decode, text:sub(i))
      if ok and type(result) == "table" then
        return result
      end
    end
  end
  return nil
end

--- Build display lines from the parsed variable map.
---@param vars table  { name → { type, repr, shape?, len? } }
---@return string[], table  lines and a map of line_number → variable_name
local function build_display(vars)
  local col_name  = 20
  local col_type  = 16
  local col_value = 40

  local header = string.format(
    "  %-*s  %-*s  %s",
    col_name, "Name",
    col_type, "Type",
    "Value"
  )
  local rule = "  " .. string.rep("─", col_name + col_type + col_value + 4)

  local lines   = { header, rule }
  local line_map = {}  -- 1-based line number → var name

  local sorted_names = vim.tbl_keys(vars)
  table.sort(sorted_names)

  for _, name in ipairs(sorted_names) do
    local info = vars[name]
    local type_str  = info.type or "?"
    local repr_str  = info.repr or ""

    -- Append shape or length annotation.
    if info.shape then
      repr_str = repr_str .. "  [shape=" .. info.shape .. "]"
    elseif info.len then
      repr_str = repr_str .. "  [len=" .. tostring(info.len) .. "]"
    end

    -- Truncate value to fit column.
    if #repr_str > col_value then
      repr_str = repr_str:sub(1, col_value - 1) .. "…"
    end

    local display_line = string.format(
      "  %-*s  %-*s  %s",
      col_name, name:sub(1, col_name),
      col_type, type_str:sub(1, col_type),
      repr_str
    )

    lines[#lines + 1] = display_line
    line_map[#lines]  = name
  end

  if #sorted_names == 0 then
    lines[#lines + 1] = "  (no variables in namespace)"
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "  <CR>  deeper inspect     q / <Esc>  close     r  refresh"

  return lines, line_map
end

-- ── Floating window ───────────────────────────────────────────────────────────

--- Apply syntax highlights to the inspector buffer.
local function highlight_inspector_buf(ibuf, line_map)
  local ins_ns = vim.api.nvim_create_namespace("jupyvim_inspector_hl")
  vim.api.nvim_buf_clear_namespace(ibuf, ins_ns, 0, -1)

  -- Header row.
  vim.api.nvim_buf_set_extmark(ibuf, ins_ns, 0, 0, {
    end_col  = 200,
    hl_group = "JupyterInspectorHeader",
    priority = 50,
  })

  -- Variable rows: highlight name, type, value in different colours.
  for lnum, _ in pairs(line_map) do
    local row = lnum - 1
    -- Name column: cols 2–21
    vim.api.nvim_buf_set_extmark(ibuf, ins_ns, row, 2, {
      end_col  = 22,
      hl_group = "JupyterInspectorName",
      priority = 50,
    })
    -- Type column: cols 24–39
    vim.api.nvim_buf_set_extmark(ibuf, ins_ns, row, 24, {
      end_col  = 40,
      hl_group = "JupyterInspectorType",
      priority = 50,
    })
    -- Value column: from col 42 onwards
    vim.api.nvim_buf_set_extmark(ibuf, ins_ns, row, 42, {
      end_col  = 200,
      hl_group = "JupyterInspectorValue",
      priority = 50,
    })
  end
end

--- Open the variable inspector for the given buffer.
---@param bufnr integer
function M.open(bufnr)
  define_highlights()

  local ok, kernel = pcall(require, "jupytervim.kernel")
  if not ok then
    require("jupytervim.utils").warn("Kernel module not available.")
    return
  end
  if kernel.status(bufnr) ~= "idle" then
    require("jupytervim.utils").warn("Kernel is busy. Wait for it to become idle.")
    return
  end

  require("jupytervim.utils").info("Fetching variables…")

  -- ── Send introspection code to the kernel ─────────────────────────────────
  -- We abuse kernel.complete() is not right here; we need to execute code and
  -- capture the output.  Use a dedicated execution with a unique msg_id and
  -- intercept the result via the pending callback mechanism.
  -- Since kernel.run_current_cell() modifies the notebook, we instead use the
  -- lower-level send() path by temporarily injecting a pending entry.
  --
  -- Simpler: temporarily attach a one-shot stream listener by executing the
  -- snippet via run_current_cell logic, but against a synthetic cell_state
  -- that captures stdout into our own handler.
  --
  -- We implement this by directly sending a JSON execute command and watching
  -- the kernel's output via a dedicated listener registered on the _state.

  local utils     = require("jupytervim.utils")
  local cell_mod  = require("jupytervim.cell")

  -- Build a throwaway cell_state so output.lua has somewhere to route messages.
  -- We don't add it to the buffer; we just use it as a key for the pending map.
  local synthetic_cs = { start_mark = -9999, index = nil, cell_type = "code" }
  local accumulated  = {}
  local done         = false

  -- Monkey-patch: temporarily override output.append for our key.
  local output = require("jupytervim.output")
  local orig_append = output.append

  output.append = function(b, cs, chunk)
    if b == bufnr and cs == synthetic_cs then
      if chunk.type == "stream" and chunk.name == "stdout" then
        accumulated[#accumulated + 1] = chunk.text
      elseif chunk.type == "status" and chunk.state == "idle" then
        done = true
      end
    else
      orig_append(b, cs, chunk)
    end
  end

  -- Execute snippet via the internal send path.
  local state_mod = require("jupytervim.kernel")
  local mid = "jvim_inspect_" .. tostring(os.time())

  -- Access the per-buffer state table directly to register the pending entry.
  -- kernel.lua exposes no state getter, so we reach in via the closure by
  -- calling run_current_cell on a synthetic stub. Instead, we use a simpler
  -- approach: just use JupyterRun on hidden code via vim.schedule.
  --
  -- The cleanest approach: add a kernel.execute_raw() helper and call it here.
  -- For now, we directly use vim.fn.chansend via the existing jobstart handle.

  -- Get job_id by asking kernel for status (it has it internally).
  -- We call kernel's internal _send via pcall on a known path.
  local sent = false
  local function try_send()
    -- Reach job_id through kernel state (since kernel.lua has no getter,
    -- we expose it temporarily via a thin wrapper call).
    local ok2, result2 = pcall(function()
      state_mod._execute_raw(bufnr, INTROSPECT_CODE, mid, synthetic_cs)
    end)
    if not ok2 then
      -- Fallback: restore and show an error.
      output.append = orig_append
      utils.warn("Inspector: could not send introspection code: " .. tostring(result2))
    else
      sent = true
    end
  end

  try_send()
  if not sent then return end

  -- Wait for output (max 3 s).
  vim.wait(3000, function() return done end, 50)
  output.append = orig_append  -- always restore

  -- ── Parse and display ──────────────────────────────────────────────────────
  local raw_text = table.concat(accumulated, "")
  local vars     = parse_json_from_output(raw_text) or {}

  local lines, line_map = build_display(vars)

  local width  = 82
  local height = math.min(#lines, math.floor(vim.o.lines * 0.7))
  local row    = math.floor((vim.o.lines   - height) / 2)
  local col    = math.floor((vim.o.columns - width)  / 2)

  local ibuf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(ibuf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(ibuf, "modifiable", false)
  vim.api.nvim_buf_set_option(ibuf, "buftype",    "nofile")

  highlight_inspector_buf(ibuf, line_map)

  local iwin = vim.api.nvim_open_win(ibuf, true, {
    relative  = "editor",
    row       = row,
    col       = col,
    width     = width,
    height    = height,
    style     = "minimal",
    border    = "rounded",
    title     = " Variable Inspector ",
    title_pos = "center",
  })
  vim.api.nvim_set_option_value("cursorline", true, { win = iwin })

  -- ── Keymaps inside the inspector window ────────────────────────────────────

  local function close()
    if vim.api.nvim_win_is_valid(iwin) then
      vim.api.nvim_win_close(iwin, true)
    end
  end

  -- q / Esc — close.
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, close, { buffer = ibuf, noremap = true, silent = true })
  end

  -- r — refresh.
  vim.keymap.set("n", "r", function()
    close()
    M.open(bufnr)
  end, { buffer = ibuf, noremap = true, silent = true })

  -- <CR> — deeper inspect on the variable under cursor.
  vim.keymap.set("n", "<CR>", function()
    local cur_lnum = vim.api.nvim_win_get_cursor(iwin)[1]
    local var_name = line_map[cur_lnum]
    if not var_name then return end
    close()
    M.inspect_var(bufnr, var_name)
  end, { buffer = ibuf, noremap = true, silent = true })
end

--- Show a deeper inspect popup for a specific variable name.
---@param bufnr integer
---@param var_name string
function M.inspect_var(bufnr, var_name)
  local ok, kernel = pcall(require, "jupytervim.kernel")
  if not ok then return end

  kernel.inspect(bufnr, var_name, #var_name, function(msg)
    local text  = msg.text or "(no documentation)"
    local lines = vim.split(text, "\n", { plain = true })

    -- Trim excess blank lines at the end.
    while lines[#lines] == "" do table.remove(lines) end

    local width  = math.min(80, vim.o.columns - 4)
    local height = math.min(#lines + 2, math.floor(vim.o.lines * 0.6))

    local dbuf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(dbuf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(dbuf, "modifiable", false)
    vim.api.nvim_buf_set_option(dbuf, "filetype",   "markdown")

    local dwin = vim.api.nvim_open_win(dbuf, true, {
      relative  = "editor",
      row       = math.floor((vim.o.lines   - height) / 2),
      col       = math.floor((vim.o.columns - width)  / 2),
      width     = width,
      height    = height,
      style     = "minimal",
      border    = "rounded",
      title     = " " .. var_name .. " ",
      title_pos = "center",
    })

    for _, key in ipairs({ "q", "<Esc>" }) do
      vim.keymap.set("n", key, function()
        if vim.api.nvim_win_is_valid(dwin) then
          vim.api.nvim_win_close(dwin, true)
        end
      end, { buffer = dbuf, noremap = true, silent = true })
    end
  end)
end

return M
