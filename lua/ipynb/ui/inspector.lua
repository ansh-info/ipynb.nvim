--- ipynb.ui.inspector
--- Variable inspector: executes a Python snippet in the kernel to retrieve
--- all user-defined variables and displays them in a floating window.
---
--- Invoked via:
---   :IpynbInspect          — show variable inspector
---   <leader>ji               — keymap (registered by keymaps.lua)
---   require("ipynb.ui.inspector").open(bufnr)
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
__jvim_skip = {'In', 'Out', 'exit', 'quit', 'get_ipython', 'open'}
__jvim_vars = {}
for __jvim_name in sorted(dir()):
    if __jvim_name.startswith('_') or __jvim_name in __jvim_skip:
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
del __jvim_json, __jvim_skip, __jvim_vars, __jvim_name, __jvim_val, __jvim_type, __jvim_repr, __jvim_entry
]]

-- ── Highlight groups ──────────────────────────────────────────────────────────

local function define_highlights()
  vim.api.nvim_set_hl(0, "IpynbInspectorHeader", { fg = "#7aa2f7", bold = true })
  vim.api.nvim_set_hl(0, "IpynbInspectorName", { fg = "#c0caf5" })
  vim.api.nvim_set_hl(0, "IpynbInspectorType", { fg = "#e0af68", italic = true })
  vim.api.nvim_set_hl(0, "IpynbInspectorValue", { fg = "#9ece6a" })
  vim.api.nvim_set_hl(0, "IpynbInspectorBorder", { fg = "#3b4261" })
end

-- ── Result parsing ────────────────────────────────────────────────────────────

--- Extract the first JSON object from mixed stdout text.
---@param text string
---@return table|nil
local function parse_json_from_output(text)
  -- The kernel may print warnings before our JSON line.
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
  local col_name = 20
  local col_type = 16
  local col_value = 40

  -- LuaJIT string.format does not support C-style dynamic-width specifiers.
  -- Build the format string with literal column widths instead.
  local row_fmt = "  %-" .. col_name .. "s  %-" .. col_type .. "s  %s"
  local header = string.format(row_fmt, "Name", "Type", "Value")
  local rule = "  " .. string.rep("─", col_name + col_type + col_value + 4)

  local lines = { header, rule }
  local line_map = {} -- 1-based line number → var name

  local sorted_names = vim.tbl_keys(vars)
  table.sort(sorted_names)

  for _, name in ipairs(sorted_names) do
    local info = vars[name]
    local type_str = info.type or "?"
    local repr_str = info.repr or ""

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

    local display_line =
      string.format(row_fmt, name:sub(1, col_name), type_str:sub(1, col_type), repr_str)

    lines[#lines + 1] = display_line
    line_map[#lines] = name
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
  local ins_ns = vim.api.nvim_create_namespace("ipynb_inspector_hl")
  vim.api.nvim_buf_clear_namespace(ibuf, ins_ns, 0, -1)

  -- Fetch all lines once so we can clamp end_col to actual line length.
  -- nvim_buf_set_extmark raises "end_col out of range" if end_col exceeds
  -- the line length, so we never pass a fixed large value.
  local all_lines = vim.api.nvim_buf_get_lines(ibuf, 0, -1, false)

  local function mark(row, scol, ecol, hl)
    local len = #(all_lines[row + 1] or "")
    if scol >= len then
      return
    end
    vim.api.nvim_buf_set_extmark(ibuf, ins_ns, row, scol, {
      end_col = math.min(ecol, len),
      hl_group = hl,
      priority = 50,
    })
  end

  -- Header row (full line).
  mark(0, 0, #(all_lines[1] or ""), "IpynbInspectorHeader")

  -- Variable rows: highlight name, type, value in different colours.
  for lnum, _ in pairs(line_map) do
    local row = lnum - 1
    local len = #(all_lines[lnum] or "")
    mark(row, 2, 22, "IpynbInspectorName")
    mark(row, 24, 40, "IpynbInspectorType")
    mark(row, 42, len, "IpynbInspectorValue")
  end
end

--- Open the variable inspector for the given buffer.
---@param bufnr integer
function M.open(bufnr)
  define_highlights()

  local ok, kernel = pcall(require, "ipynb.kernel")
  if not ok then
    require("ipynb.utils").warn("Kernel module not available.")
    return
  end
  if kernel.status(bufnr) ~= "idle" then
    require("ipynb.utils").warn("Kernel is busy. Wait for it to become idle.")
    return
  end

  local utils = require("ipynb.utils")
  utils.info("Fetching variables...")

  -- Execute the introspection snippet via the dedicated snippet path.
  -- kernel.execute_snippet bypasses the cell output pipeline entirely so no
  -- extmarks or cell state are touched. The callback fires asynchronously
  -- once the kernel sends status:idle for this execution.
  kernel.execute_snippet(bufnr, INTROSPECT_CODE, function(raw_text, err)
    if err then
      utils.warn("Inspector: " .. err)
      return
    end

    local vars = parse_json_from_output(raw_text or "") or {}
    local lines, line_map = build_display(vars)

    local width = math.max(1, math.min(82, vim.o.columns - 2))
    local height = math.max(1, math.min(#lines, math.floor(vim.o.lines * 0.7)))
    local row = math.max(0, math.floor((vim.o.lines - height) / 2))
    local col = math.max(0, math.floor((vim.o.columns - width) / 2))

    local ibuf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(ibuf, 0, -1, false, lines)
    vim.bo[ibuf].modifiable = false
    vim.bo[ibuf].buftype = "nofile"

    highlight_inspector_buf(ibuf, line_map)

    local iwin = vim.api.nvim_open_win(ibuf, true, {
      relative = "editor",
      row = row,
      col = col,
      width = width,
      height = height,
      style = "minimal",
      border = "rounded",
      title = " Variable Inspector ",
      title_pos = "center",
    })
    vim.api.nvim_set_option_value("cursorline", true, { win = iwin })

    -- ── Keymaps inside the inspector window ──────────────────────────────────

    local function close()
      if vim.api.nvim_win_is_valid(iwin) then
        vim.api.nvim_win_close(iwin, true)
      end
    end

    -- q / Esc - close.
    for _, key in ipairs({ "q", "<Esc>" }) do
      vim.keymap.set("n", key, close, { buffer = ibuf, noremap = true, silent = true })
    end

    -- r - refresh.
    vim.keymap.set("n", "r", function()
      close()
      M.open(bufnr)
    end, { buffer = ibuf, noremap = true, silent = true })

    -- <CR> - deeper inspect on the variable under cursor.
    vim.keymap.set("n", "<CR>", function()
      local cur_lnum = vim.api.nvim_win_get_cursor(iwin)[1]
      local var_name = line_map[cur_lnum]
      if not var_name then
        return
      end
      close()
      M.inspect_var(bufnr, var_name)
    end, { buffer = ibuf, noremap = true, silent = true })
  end)
end

--- Show a deeper inspect popup for a specific variable name.
---@param bufnr integer
---@param var_name string
function M.inspect_var(bufnr, var_name)
  local ok, kernel = pcall(require, "ipynb.kernel")
  if not ok then
    return
  end

  kernel.inspect(bufnr, var_name, #var_name, function(msg)
    local text = msg.text or "(no documentation)"
    local lines = vim.split(text, "\n", { plain = true })

    -- Trim excess blank lines at the end.
    while lines[#lines] == "" do
      table.remove(lines)
    end

    local width = math.max(1, math.min(80, vim.o.columns - 4))
    local height = math.max(1, math.min(#lines + 2, math.floor(vim.o.lines * 0.6)))

    local dbuf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(dbuf, 0, -1, false, lines)
    vim.bo[dbuf].modifiable = false
    vim.bo[dbuf].filetype = "markdown"

    local dwin = vim.api.nvim_open_win(dbuf, true, {
      relative = "editor",
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      width = width,
      height = height,
      style = "minimal",
      border = "rounded",
      title = " " .. var_name .. " ",
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

M.define_highlights = define_highlights

return M
