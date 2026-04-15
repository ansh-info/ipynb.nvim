--- ipynb.core.cell
--- Cell lifecycle: render cells into a buffer, anchor them with extmarks,
--- and expose mutation helpers (add, delete, split, merge).
---
--- Buffer layout (one cell):
---
---   ╭── [lang_icon] [lang] · [exec_count] ─── (virt_line, above content)
---   <actual source lines in the buffer>
---   ╰── ✓ 0.23s ─────────────────────────────  (virt_line, below content)
---
--- Each cell is tracked by a *pair* of extmarks:
---   - start_mark  : placed at column 0 of the first source line
---   - end_mark    : placed at column 0 of the last source line
---
--- The cell table stored per-buffer:
---   {
---     index          : integer,   -- 1-based position in notebook.cells
---     cell_type      : string,
---     language       : string,
---     execution_count: integer|nil,
---     start_mark     : integer,   -- extmark id
---     end_mark       : integer,   -- extmark id
---     output_mark    : integer|nil, -- extmark id for output virt_lines
---     bufnr          : integer,
---   }

local config = require("ipynb.config")
local utils = require("ipynb.utils")

local M = {}

-- Namespace for all cell-related extmarks.
local NS = vim.api.nvim_create_namespace("ipynb_cells")

-- ── Highlight groups (defined once on first load) ─────────────────────────────

local hl_defined = false
local function define_highlights()
  if hl_defined then
    return
  end
  hl_defined = true

  -- Cell border colours.
  vim.api.nvim_set_hl(0, "IpynbCellBorder", { fg = "#4a9eff", bold = true })
  vim.api.nvim_set_hl(0, "IpynbCellBorderMd", { fg = "#f9c74f", bold = true })
  vim.api.nvim_set_hl(0, "IpynbCellBorderRaw", { fg = "#aaaaaa" })
  vim.api.nvim_set_hl(0, "IpynbCellTag", { fg = "#a0c4ff", italic = true })

  -- Output colours.
  vim.api.nvim_set_hl(0, "IpynbOutputText", { fg = "#d4d4d4" })
  vim.api.nvim_set_hl(0, "IpynbOutputError", { fg = "#f28b82", bold = true })
  vim.api.nvim_set_hl(0, "IpynbOutputErrorTrace", { fg = "#e88080" })
  vim.api.nvim_set_hl(0, "IpynbOutputResult", { fg = "#a8d8a8", italic = true })
  vim.api.nvim_set_hl(0, "IpynbOutputMeta", { fg = "#888888", italic = true })

  -- Active cell background.
  vim.api.nvim_set_hl(0, "IpynbActiveCell", { bg = "#1a2233" })

  -- Status icons.
  vim.api.nvim_set_hl(0, "IpynbStatusIdle", { fg = "#50fa7b" })
  vim.api.nvim_set_hl(0, "IpynbStatusBusy", { fg = "#f1fa8c" })
  vim.api.nvim_set_hl(0, "IpynbStatusError", { fg = "#f28b82" })
end

-- ── Border builders ───────────────────────────────────────────────────────────

--- Return the highlight group to use for a given cell type.
---@param cell_type string
---@return string hl_group
local function border_hl(cell_type)
  if cell_type == "markdown" then
    return "IpynbCellBorderMd"
  end
  if cell_type == "raw" then
    return "IpynbCellBorderRaw"
  end
  return "IpynbCellBorder"
end

--- Build the top border virt_line for a cell.
---   ╭─── [icon lang] · [N] ──────────────────╮
---@param cell_type string
---@param language string
---@param exec_count integer|nil
---@param width integer  window width in columns (approximate)
---@return table[]  virt_line chunks  (list of {text, hl})
local function top_border(cell_type, language, exec_count, width)
  local cfg = config.get()
  local bc = cfg.ui.border_chars
  local hl = border_hl(cell_type)

  local icon = cfg.ui.lang_icons[language] or cfg.ui.lang_icons[""]

  -- Tag section: "  python"
  local tag = " " .. icon .. " " .. language .. " "
  if exec_count and cfg.ui.show_execution_count then
    tag = tag .. "· [" .. tostring(exec_count) .. "] "
  end

  -- Left part:  ╭─ tag ─
  local left = bc.top_left .. bc.horizontal .. tag

  -- Fill the rest up to width - 1 (leave room for top_right)
  local fill_len = math.max(2, width - vim.fn.strdisplaywidth(left) - 1)
  local right = string.rep(bc.horizontal, fill_len) .. bc.top_right

  return {
    { left, hl },
    { right, hl },
  }
end

--- Build the bottom border virt_line for a cell.
---   ╰── ✓ 0.23s ────────────────────────────╯
---@param status "idle"|"busy"|"error"|nil
---@param elapsed_ms integer|nil
---@param width integer
---@return table[]
local function bottom_border(status, elapsed_ms, width)
  local cfg = config.get()
  local bc = cfg.ui.border_chars
  local hl = "IpynbCellBorder"

  -- Status icon + elapsed time.
  local meta = ""
  if status == "busy" then
    meta = "  … "
  elseif status == "error" then
    meta = "  ✗ "
  elseif status == "idle" and elapsed_ms and cfg.ui.show_elapsed_time then
    local secs = elapsed_ms / 1000
    meta = string.format("  ✓ %.2fs ", secs)
  elseif status == "idle" then
    meta = "  ✓ "
  end

  local meta_hl = "IpynbOutputMeta"
  if status == "error" then
    meta_hl = "IpynbStatusError"
  end
  if status == "busy" then
    meta_hl = "IpynbStatusBusy"
  end
  if status == "idle" then
    meta_hl = "IpynbStatusIdle"
  end

  local left = bc.bottom_left .. bc.horizontal
  local fill_len =
    math.max(2, width - vim.fn.strdisplaywidth(left) - vim.fn.strdisplaywidth(meta) - 1)
  local right = string.rep(bc.horizontal, fill_len) .. bc.bottom_right

  return {
    { left, hl },
    { meta, meta_hl },
    { right, hl },
  }
end

-- ── Buffer-local state ────────────────────────────────────────────────────────

-- Map: bufnr → { cells = CellState[], notebook = Notebook }
local buf_state = {}

-- Guard: prevents check_structural_integrity from triggering on the
-- TextChanged event that render() itself fires during recovery.
local _integrity_guard = {}

-- Hooks called after each render() with (bufnr, cells).
-- Used by kernel/init.lua to remap stale pending cell_state references.
local _render_hooks = {}

--- Register a callback invoked after every render().
--- cb(bufnr, cells) is called with the freshly-built state.cells array.
---@param cb function
function M.register_render_hook(cb)
  _render_hooks[#_render_hooks + 1] = cb
end

--- Return the width of the window displaying `bufnr`.
--- Falls back to window 0 if the buffer is not visible.
---@param bufnr integer
---@return integer
local function buf_win_width(bufnr)
  local win = vim.fn.bufwinid(bufnr)
  if win == -1 then
    win = 0
  end
  return vim.api.nvim_win_get_width(win)
end

--- Return or create the state table for a buffer.
---@param bufnr integer
---@return table
local function get_state(bufnr)
  if not buf_state[bufnr] then
    buf_state[bufnr] = { cells = {}, notebook = nil }
  end
  return buf_state[bufnr]
end

--- Free state when a buffer is wiped.
function M.on_buf_delete(bufnr)
  buf_state[bufnr] = nil
end

-- ── Core render ───────────────────────────────────────────────────────────────

--- Render all cells of a notebook into the given buffer.
--- Clears the buffer first, then writes source lines for every cell separated
--- by a single blank line, and places extmarks for the top/bottom borders.
---
---@param bufnr integer
---@param notebook table  Notebook from notebook.lua
---@param opts table|nil  Options:
---   opts.preserve_undo (boolean) - when true, skip the undolevels=-1 block so
---   that in-cell typing undo history is preserved across the render call.
---   Pass this from user-facing structural ops (add/delete/move/etc.) so that
---   typing done before the op remains undoable afterwards.
---   Omit (or false) for initial file load, VimResized, and integrity-recovery
---   renders where starting with a clean undo tree is correct.
function M.render(bufnr, notebook, opts)
  define_highlights()

  local state = get_state(bufnr)

  -- Release output store, image placements, and re-entrancy guards for all
  -- existing cells BEFORE the namespace wipe so old start_mark-based keys can
  -- still be resolved.  Without this, every structural operation (move, delete,
  -- duplicate, paste) leaks entries in output._store and image._placements,
  -- and active image placements are never closed.
  if state.cells and #state.cells > 0 then
    local ok_out, output_mod = pcall(require, "ipynb.kernel.output")
    if ok_out then
      for _, cs in ipairs(state.cells) do
        output_mod.clear(bufnr, cs)
      end
    end
  end

  state.notebook = notebook
  state.cells = {}

  -- Unlock the buffer for writing.
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_option(bufnr, "readonly", false)

  -- Optionally make all nvim_buf_set_lines calls undo-invisible.
  --
  -- When preserve_undo is false (default): set undolevels=-1 before writes so
  -- render() entries never appear in the undo tree.  Used for initial file load
  -- and check_structural_integrity recovery where a clean undo start is correct.
  --
  -- When preserve_undo is true: skip this block so that typing the user did
  -- before a structural op (add/delete/move/duplicate/paste/toggle) stays
  -- undoable after the op.  The render() writes for structural ops do enter the
  -- undo tree, but check_structural_integrity will recover if the user undoes
  -- through them (it detects divergence and re-renders from the notebook model).
  local preserve_undo = opts and opts.preserve_undo or false
  local saved_ul
  if not preserve_undo then
    saved_ul = vim.api.nvim_buf_get_option(bufnr, "undolevels")
    vim.api.nvim_buf_set_option(bufnr, "undolevels", -1)
  end

  -- Clear everything.
  vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})

  local win_width = buf_win_width(bufnr)

  local current_line = 0 -- 0-based

  for i, cell in ipairs(notebook.cells) do
    local source_lines = vim.split(cell.source, "\n", { plain = true })
    -- Ensure at least one line so the cell is addressable.
    if #source_lines == 0 then
      source_lines = { "" }
    end

    local start_line = current_line

    -- Insert source into buffer.
    vim.api.nvim_buf_set_lines(bufnr, current_line, current_line, false, source_lines)
    local end_line = current_line + #source_lines - 1 -- last line of this cell (0-based, inclusive)

    local language = require("ipynb.core.notebook").cell_language(notebook, cell)

    -- ── Top border extmark ──────────────────────────────────────────────
    local top_vl = top_border(cell.cell_type, language, cell.execution_count, win_width)
    local start_mark = vim.api.nvim_buf_set_extmark(bufnr, NS, start_line, 0, {
      virt_lines = { top_vl },
      virt_lines_above = true,
      priority = 100,
    })

    -- ── Bottom border extmark ───────────────────────────────────────────
    local bot_vl = bottom_border(nil, nil, win_width)
    local end_mark = vim.api.nvim_buf_set_extmark(bufnr, NS, end_line, 0, {
      virt_lines = { bot_vl },
      virt_lines_above = false,
      priority = 100,
    })

    -- ── Record cell state ───────────────────────────────────────────────
    state.cells[i] = {
      index = i,
      cell_id = cell.id, -- stable notebook cell id; used to remap kernel pending
      cell_type = cell.cell_type,
      language = language,
      execution_count = cell.execution_count,
      start_mark = start_mark,
      end_mark = end_mark,
      output_mark = nil,
      bufnr = bufnr,
      status = nil,
      elapsed_ms = nil,
    }

    -- Restore saved outputs from the notebook file (deferred so extmarks
    -- are fully placed before image positioning is attempted).
    if cell.outputs and #cell.outputs > 0 then
      local cs = state.cells[i]
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          local ok, output = pcall(require, "ipynb.kernel.output")
          if ok then
            output.restore(bufnr, cs, cell.outputs)
          end
        end
      end)
    end

    -- Advance: add a blank separator line between cells (not after the last).
    current_line = end_line + 1
    if i < #notebook.cells then
      vim.api.nvim_buf_set_lines(bufnr, current_line, current_line, false, { "" })
      current_line = current_line + 1
    end
  end

  -- Set filetype from notebook kernel language for correct treesitter / LSP.
  local ft = require("ipynb.core.notebook").notebook_language(notebook)
  vim.api.nvim_buf_set_option(bufnr, "filetype", ft)

  -- Restore undo tracking (only when we suppressed it above).
  if not preserve_undo then
    vim.api.nvim_buf_set_option(bufnr, "undolevels", saved_ul)
  end

  -- Notify render hooks (e.g. kernel remap of pending cell_state refs).
  -- state.cells is fully built at this point.
  for _, hook in ipairs(_render_hooks) do
    pcall(hook, bufnr, state.cells)
  end

  -- Apply markdown decorations after all cells are placed.
  -- Deferred so extmark positions are stable before markdown.render() reads them.
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      local ok, markdown = pcall(require, "ipynb.ui.markdown")
      if ok then
        markdown.render(bufnr)
      end
    end
  end)

  utils.info(string.format("Loaded notebook: %d cells", #notebook.cells))
end

-- ── Navigation helpers ────────────────────────────────────────────────────────

--- Return the line range [start, end] (0-based, inclusive) of a cell by
--- reading its start/end extmarks.
---@param bufnr integer
---@param cell_state table
---@return integer start_line, integer end_line
local function cell_line_range(bufnr, cell_state)
  local sm = vim.api.nvim_buf_get_extmark_by_id(bufnr, NS, cell_state.start_mark, {})
  local em = vim.api.nvim_buf_get_extmark_by_id(bufnr, NS, cell_state.end_mark, {})
  return sm[1] or 0, em[1] or 0
end

--- Find which cell the cursor is currently inside.
--- Returns the cell_state table, or nil if not inside any cell.
---@param bufnr integer
---@return table|nil cell_state, integer|nil cell_index
function M.cell_at_cursor(bufnr)
  local state = get_state(bufnr)
  local cur_row = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-based

  for i, cs in ipairs(state.cells) do
    local s, e = cell_line_range(bufnr, cs)
    -- Extend the range to cover the blank separator line that follows each
    -- cell (inserted by render()).  The upper boundary is the start of the
    -- next cell (exclusive), so the separator belongs to the cell above it.
    local limit = e
    if i < #state.cells then
      local ns, _ = cell_line_range(bufnr, state.cells[i + 1])
      limit = ns - 1 -- include blank line(s) between the two cells
    end
    if cur_row >= s and cur_row <= limit then
      return cs, i
    end
  end
  return nil, nil
end

--- Snap the cursor to the first line of the nearest cell.
--- Called when CursorMoved detects the cursor is outside all cell regions.
---@param bufnr integer
---@param cur_row integer  current 0-based row
function M.snap_cursor_to_nearest(bufnr, cur_row)
  local state = get_state(bufnr)
  if not state or #state.cells == 0 then
    return
  end
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line_count == 0 then
    return
  end
  local best_row = nil
  local best_dist = math.huge
  for _, cs in ipairs(state.cells) do
    local s, _ = cell_line_range(bufnr, cs)
    -- Skip extmarks that undo has moved beyond the current buffer length.
    if s < line_count then
      local dist = math.abs(s - cur_row)
      if dist < best_dist then
        best_dist = dist
        best_row = s
      end
    end
  end
  if best_row then
    -- Clamp to buffer bounds in case of any remaining drift.
    local safe = math.min(best_row, line_count - 1)
    vim.api.nvim_win_set_cursor(0, { safe + 1, 0 })
  end
end

--- Move cursor to the next cell.
---@param bufnr integer
function M.goto_next_cell(bufnr)
  local state = get_state(bufnr)
  local _, idx = M.cell_at_cursor(bufnr)
  if not idx or idx >= #state.cells then
    return
  end

  local next_cs = state.cells[idx + 1]
  local s, _ = cell_line_range(bufnr, next_cs)
  vim.api.nvim_win_set_cursor(0, { s + 1, 0 })
end

--- Move cursor to the previous cell.
---@param bufnr integer
function M.goto_prev_cell(bufnr)
  local state = get_state(bufnr)
  local _, idx = M.cell_at_cursor(bufnr)
  if not idx or idx <= 1 then
    return
  end

  local prev_cs = state.cells[idx - 1]
  local s, _ = cell_line_range(bufnr, prev_cs)
  vim.api.nvim_win_set_cursor(0, { s + 1, 0 })
end

-- ── Cell source extraction ────────────────────────────────────────────────────

--- Return the current source text of a cell as a string, read from the buffer.
---@param bufnr integer
---@param cell_state table
---@return string
function M.get_cell_source(bufnr, cell_state)
  local s, e = cell_line_range(bufnr, cell_state)
  local lines = vim.api.nvim_buf_get_lines(bufnr, s, e + 1, false)
  return table.concat(lines, "\n")
end

--- Return all cells and their sources that appear before a given cell index (1-based).
---@param bufnr integer
---@param up_to integer  Exclusive upper bound (cells 1 .. up_to-1)
---@return table[]  list of {cell_state, source}
function M.cells_above(bufnr, up_to)
  local state = get_state(bufnr)
  local result = {}
  for i = 1, math.min(up_to - 1, #state.cells) do
    local cs = state.cells[i]
    result[#result + 1] = { cell_state = cs, source = M.get_cell_source(bufnr, cs) }
  end
  return result
end

-- ── Cell mutation ─────────────────────────────────────────────────────────────

--- Add a new empty cell below the cell at `idx`.
---@param bufnr integer
---@param idx integer  1-based index of the reference cell
---@param cell_type string|nil  "code" (default) or "markdown"
function M.add_cell_below(bufnr, idx, cell_type)
  local state = get_state(bufnr)
  local notebook = state.notebook
  if not notebook then
    return
  end

  cell_type = cell_type or "code"
  -- Insert a new empty cell into the notebook model.
  local new_cell = {
    id = require("ipynb.core.notebook").gen_cell_id
        and require("ipynb.core.notebook").gen_cell_id()
      or utils.uid(),
    cell_type = cell_type,
    source = "",
    outputs = cell_type == "code" and {} or nil,
    metadata = {},
    execution_count = cell_type == "code" and nil or nil,
  }
  table.insert(notebook.cells, idx + 1, new_cell)

  -- Re-render the whole buffer to reflect the new cell.
  -- preserve_undo keeps any typing the user did before this op undoable.
  M.render(bufnr, notebook, { preserve_undo = true })

  -- Defer cursor placement until after render-triggered autocmds settle.
  -- M.render() rebuilds all extmarks; CursorMoved fires during the rebuild
  -- and snap_cursor_to_nearest can fire with incomplete state.  Waiting one
  -- tick ensures extmarks are stable before we move the cursor.
  local captured_idx = idx
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    local new_cs = state.cells[captured_idx + 1]
    if new_cs then
      local s, _ = cell_line_range(bufnr, new_cs)
      vim.api.nvim_win_set_cursor(0, { s + 1, 0 })
      vim.cmd("startinsert")
    end
  end)
end

--- Add a new empty cell above the cell at `idx`.
---@param bufnr integer
---@param idx integer
---@param cell_type string|nil  "code" (default) or "markdown"
function M.add_cell_above(bufnr, idx, cell_type)
  local state = get_state(bufnr)
  local notebook = state.notebook
  if not notebook then
    return
  end

  cell_type = cell_type or "code"
  local new_cell = {
    id = utils.uid(),
    cell_type = cell_type,
    source = "",
    outputs = cell_type == "code" and {} or nil,
    metadata = {},
    execution_count = nil,
  }
  table.insert(notebook.cells, idx, new_cell)

  M.render(bufnr, notebook, { preserve_undo = true })

  local captured_idx = idx
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    local new_cs = state.cells[captured_idx]
    if new_cs then
      local s, _ = cell_line_range(bufnr, new_cs)
      vim.api.nvim_win_set_cursor(0, { s + 1, 0 })
      vim.cmd("startinsert")
    end
  end)
end

--- Delete the cell at `idx`.
---@param bufnr integer
---@param idx integer
function M.delete_cell(bufnr, idx)
  local state = get_state(bufnr)
  local notebook = state.notebook
  if not notebook then
    return
  end
  if #notebook.cells <= 1 then
    utils.warn("Cannot delete the only remaining cell.")
    return
  end

  table.remove(notebook.cells, idx)
  M.render(bufnr, notebook, { preserve_undo = true })
end

--- Move the cell at `idx` one position up (swap with the cell above).
---@param bufnr integer
---@param idx integer
function M.move_cell_up(bufnr, idx)
  local state = get_state(bufnr)
  local notebook = state.notebook
  if not notebook or idx <= 1 then
    return
  end

  notebook.cells[idx], notebook.cells[idx - 1] = notebook.cells[idx - 1], notebook.cells[idx]
  M.render(bufnr, notebook, { preserve_undo = true })

  local captured = idx - 1
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    local cs = state.cells[captured]
    if cs then
      local s, _ = cell_line_range(bufnr, cs)
      vim.api.nvim_win_set_cursor(0, { s + 1, 0 })
    end
  end)
end

--- Move the cell at `idx` one position down (swap with the cell below).
---@param bufnr integer
---@param idx integer
function M.move_cell_down(bufnr, idx)
  local state = get_state(bufnr)
  local notebook = state.notebook
  if not notebook or idx >= #notebook.cells then
    return
  end

  notebook.cells[idx], notebook.cells[idx + 1] = notebook.cells[idx + 1], notebook.cells[idx]
  M.render(bufnr, notebook, { preserve_undo = true })

  local captured = idx + 1
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    local cs = state.cells[captured]
    if cs then
      local s, _ = cell_line_range(bufnr, cs)
      vim.api.nvim_win_set_cursor(0, { s + 1, 0 })
    end
  end)
end

--- Duplicate the cell at `idx`, inserting the copy immediately below.
--- Outputs and execution_count are cleared on the copy.
---@param bufnr integer
---@param idx integer
function M.duplicate_cell(bufnr, idx)
  local state = get_state(bufnr)
  local notebook = state.notebook
  if not notebook then
    return
  end

  local copy = vim.deepcopy(notebook.cells[idx])
  copy.id = utils.uid()
  copy.execution_count = nil
  if copy.outputs then
    copy.outputs = {}
  end

  table.insert(notebook.cells, idx + 1, copy)
  M.render(bufnr, notebook, { preserve_undo = true })

  local captured = idx + 1
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    local cs = state.cells[captured]
    if cs then
      local s, _ = cell_line_range(bufnr, cs)
      vim.api.nvim_win_set_cursor(0, { s + 1, 0 })
    end
  end)
end

-- ── Cell yank / paste ─────────────────────────────────────────────────────────

-- Process-local yank register: holds one deep-copied notebook cell.
local _yank_register = nil

--- Copy the cell at `idx` into the yank register.
---@param bufnr integer
---@param idx integer
function M.yank_cell(bufnr, idx)
  local state = get_state(bufnr)
  local notebook = state.notebook
  if not notebook then
    return
  end

  _yank_register = vim.deepcopy(notebook.cells[idx])
  utils.info("Cell yanked.")
end

--- Paste the yanked cell below the cell at `idx`.
--- Outputs and execution_count are cleared on the pasted copy.
---@param bufnr integer
---@param idx integer
function M.paste_cell(bufnr, idx)
  if not _yank_register then
    utils.warn("No cell in yank register.")
    return
  end

  local state = get_state(bufnr)
  local notebook = state.notebook
  if not notebook then
    return
  end

  local pasted = vim.deepcopy(_yank_register)
  pasted.id = utils.uid()
  pasted.execution_count = nil
  if pasted.outputs then
    pasted.outputs = {}
  end

  table.insert(notebook.cells, idx + 1, pasted)
  M.render(bufnr, notebook, { preserve_undo = true })

  local captured = idx + 1
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    local cs = state.cells[captured]
    if cs then
      local s, _ = cell_line_range(bufnr, cs)
      vim.api.nvim_win_set_cursor(0, { s + 1, 0 })
    end
  end)
end

--- Toggle the cell at `idx` between "code" and "markdown".
--- Outputs and execution_count are cleared when switching to markdown.
---@param bufnr integer
---@param idx integer
function M.toggle_cell_type(bufnr, idx)
  local state = get_state(bufnr)
  local notebook = state.notebook
  if not notebook then
    return
  end

  local c = notebook.cells[idx]
  if c.cell_type == "code" then
    c.cell_type = "markdown"
    c.outputs = nil
    c.execution_count = nil
  else
    c.cell_type = "code"
    c.outputs = {}
    c.execution_count = nil
  end

  M.render(bufnr, notebook, { preserve_undo = true })

  local captured = idx
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    local cs = state.cells[captured]
    if cs then
      local s, _ = cell_line_range(bufnr, cs)
      vim.api.nvim_win_set_cursor(0, { s + 1, 0 })
    end
  end)
end

--- Split the cell at `idx` at the current cursor line into two cells of the
--- same type.  The upper cell keeps lines above the cursor, the lower cell
--- gets lines from the cursor down.
---@param bufnr integer
---@param idx integer
function M.split_cell(bufnr, idx)
  local state = get_state(bufnr)
  local notebook = state.notebook
  if not notebook then
    return
  end

  local cs = state.cells[idx]
  if not cs then
    return
  end

  -- Determine the split line relative to the cell start.
  local s, e = cell_line_range(bufnr, cs)
  local cur_row = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-based
  local rel = cur_row - s -- 0-based offset within the cell

  local all_lines = vim.api.nvim_buf_get_lines(bufnr, s, e + 1, false)
  if rel < 0 then
    rel = 0
  end
  if rel > #all_lines then
    rel = #all_lines
  end

  local upper_lines = vim.list_slice(all_lines, 1, rel)
  local lower_lines = vim.list_slice(all_lines, rel + 1)

  -- Update the original cell's source and clear its outputs.
  local c = notebook.cells[idx]
  c.source = table.concat(upper_lines, "\n")
  c.outputs = c.cell_type == "code" and {} or nil
  c.execution_count = nil

  -- Insert a new cell below with the lower portion.
  local new_cell = {
    id = require("ipynb.core.notebook").gen_cell_id
        and require("ipynb.core.notebook").gen_cell_id()
      or utils.uid(),
    cell_type = c.cell_type,
    source = table.concat(lower_lines, "\n"),
    outputs = c.cell_type == "code" and {} or nil,
    metadata = {},
    execution_count = nil,
  }
  table.insert(notebook.cells, idx + 1, new_cell)

  M.render(bufnr, notebook, { preserve_undo = true })

  -- Place cursor at the start of the new lower cell.
  local captured = idx + 1
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    local new_cs = state.cells[captured]
    if new_cs then
      local ns, _ = cell_line_range(bufnr, new_cs)
      vim.api.nvim_win_set_cursor(0, { ns + 1, 0 })
    end
  end)
end

--- Merge the cell at `idx` with the cell at `idx+1`.
--- The merged cell keeps the cell_type of the upper cell.
---@param bufnr integer
---@param idx integer
function M.merge_cell_below(bufnr, idx)
  local state = get_state(bufnr)
  local notebook = state.notebook
  if not notebook then
    return
  end

  if idx >= #notebook.cells then
    utils.warn("No cell below to merge with.")
    return
  end

  local upper = notebook.cells[idx]
  local lower = notebook.cells[idx + 1]

  -- Concatenate sources with a newline separator.
  local upper_src = upper.source or ""
  local lower_src = lower.source or ""
  if upper_src ~= "" and lower_src ~= "" then
    upper.source = upper_src .. "\n" .. lower_src
  else
    upper.source = upper_src .. lower_src
  end

  -- Clear outputs and execution count since the merged cell is a new unit.
  upper.outputs = upper.cell_type == "code" and {} or nil
  upper.execution_count = nil

  -- Remove the lower cell from the notebook model.
  table.remove(notebook.cells, idx + 1)

  M.render(bufnr, notebook, { preserve_undo = true })

  -- Place cursor at the original cell position.
  local captured = idx
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    local cs = state.cells[captured]
    if cs then
      local ns, _ = cell_line_range(bufnr, cs)
      vim.api.nvim_win_set_cursor(0, { ns + 1, 0 })
    end
  end)
end

-- ── Output rendering ──────────────────────────────────────────────────────────

--- Append a virt_lines output block below the cell.
--- Replaces any existing output extmark for this cell.
---@param bufnr integer
---@param cell_state table
---@param virt_lines table[][]  list of virt_line chunk lists
function M.set_output_virt_lines(bufnr, cell_state, virt_lines)
  -- Remove old output extmark if it exists.
  if cell_state.output_mark then
    vim.api.nvim_buf_del_extmark(bufnr, NS, cell_state.output_mark)
    cell_state.output_mark = nil
  end

  if not virt_lines or #virt_lines == 0 then
    return
  end

  local _, e = cell_line_range(bufnr, cell_state)
  cell_state.output_mark = vim.api.nvim_buf_set_extmark(bufnr, NS, e, 0, {
    virt_lines = virt_lines,
    virt_lines_above = false,
    priority = 90,
  })
end

--- Clear the output virt_lines for a cell.
---@param bufnr integer
---@param cell_state table
function M.clear_output(bufnr, cell_state)
  M.set_output_virt_lines(bufnr, cell_state, {})
end

--- Update the bottom border of a cell to show status + elapsed time.
---@param bufnr integer
---@param cell_state table
---@param status "idle"|"busy"|"error"
---@param elapsed_ms integer|nil
function M.update_status(bufnr, cell_state, status, elapsed_ms)
  cell_state.status = status
  cell_state.elapsed_ms = elapsed_ms

  local win_width = buf_win_width(bufnr)
  local bot_vl = bottom_border(status, elapsed_ms, win_width)

  local _, e = cell_line_range(bufnr, cell_state)
  vim.api.nvim_buf_set_extmark(bufnr, NS, e, 0, {
    id = cell_state.end_mark,
    virt_lines = { bot_vl },
    virt_lines_above = false,
    priority = 100,
  })
end

--- Update the top border execution count display.
---@param bufnr integer
---@param cell_state table
---@param exec_count integer
function M.update_execution_count(bufnr, cell_state, exec_count)
  cell_state.execution_count = exec_count

  local win_width = buf_win_width(bufnr)
  local top_vl = top_border(cell_state.cell_type, cell_state.language, exec_count, win_width)

  local s, _ = cell_line_range(bufnr, cell_state)
  vim.api.nvim_buf_set_extmark(bufnr, NS, s, 0, {
    id = cell_state.start_mark,
    virt_lines = { top_vl },
    virt_lines_above = true,
    priority = 100,
  })
end

-- ── Public accessors ──────────────────────────────────────────────────────────

--- Return all cell states for a buffer.
---@param bufnr integer
---@return table[]
function M.get_cells(bufnr)
  return get_state(bufnr).cells
end

--- Return the notebook associated with a buffer.
---@param bufnr integer
---@return table|nil
function M.get_notebook(bufnr)
  return get_state(bufnr).notebook
end

--- Re-anchor every cell's end_mark after text edits.
---
--- Pressing 'o' on a cell's last line inserts a new line BELOW the end_mark
--- (the insertion point is at the END of that line, past col 0 where the mark
--- sits).  Neovim therefore leaves end_mark on the original line while new
--- content grows below it - outside the visible cell border.
---
--- This function recomputes the correct last line for each cell by reading the
--- next cell's start_mark (which tracks correctly) and moving end_mark there.
--- It also keeps any output_mark co-located with end_mark so output stays
--- anchored to the bottom of the cell.
---
--- Called from InsertLeave and TextChanged autocmds in notebook_buf.lua.
---@param bufnr integer
---@param active_idx integer|nil  1-based index of the cell being edited.
---   When provided only that cell and its immediate neighbours are processed
---   (O(1) extmark writes instead of O(n)).  Pass nil to reanchor all cells.
function M.reanchor_end_marks(bufnr, active_idx)
  local state = get_state(bufnr)
  if not state or #state.cells == 0 then
    return
  end
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local win_width = buf_win_width(bufnr)

  -- Clamp the iteration range to the active cell and its neighbours.
  -- Cells further away cannot have had their end_mark affected by this edit.
  -- Fall back to all cells when active_idx is unknown.
  local i_start = active_idx and math.max(1, active_idx - 1) or 1
  local i_end = active_idx and math.min(#state.cells, active_idx + 1) or #state.cells

  for i = i_start, i_end do
    local cs = state.cells[i]
    if not cs then
      goto continue
    end
    local sm = vim.api.nvim_buf_get_extmark_by_id(bufnr, NS, cs.start_mark, {})
    if not sm or #sm == 0 then
      goto continue
    end
    local start_row = sm[1]

    -- If undo shrank the buffer so that start_mark is now beyond the last
    -- line, skip this cell entirely - moving its extmarks would cluster all
    -- borders at row 0 and make the buffer look blank.
    if start_row >= line_count then
      goto continue
    end

    -- Compute the correct last line for this cell.
    local new_end
    if i < #state.cells then
      local next_sm =
        vim.api.nvim_buf_get_extmark_by_id(bufnr, NS, state.cells[i + 1].start_mark, {})
      if next_sm and #next_sm > 0 and next_sm[1] > start_row + 1 then
        -- Layout: ... [cell lines] [separator blank] [next cell line 0] ...
        -- separator is at next_sm[1]-1, cell ends at next_sm[1]-2.
        new_end = math.max(start_row, next_sm[1] - 2)
      end
    else
      new_end = math.max(start_row, line_count - 1)
    end

    if not new_end then
      goto continue
    end

    -- Always clamp to valid buffer range.
    new_end = math.min(new_end, line_count - 1)

    local cur_em = vim.api.nvim_buf_get_extmark_by_id(bufnr, NS, cs.end_mark, {})
    if cur_em and #cur_em > 0 and cur_em[1] == new_end then
      goto continue -- already at the correct line
    end

    -- Move end_mark to the correct last line.
    local bot_vl = bottom_border(cs.status, cs.elapsed_ms, win_width)
    vim.api.nvim_buf_set_extmark(bufnr, NS, new_end, 0, {
      id = cs.end_mark,
      virt_lines = { bot_vl },
      virt_lines_above = false,
      priority = 100,
    })

    -- Keep output_mark co-located with end_mark so output stays at the
    -- bottom of the cell rather than floating at the old end line.
    if cs.output_mark then
      local om = vim.api.nvim_buf_get_extmark_by_id(bufnr, NS, cs.output_mark, { details = true })
      if om and #om > 0 then
        local details = om[3]
        if details and details.virt_lines then
          vim.api.nvim_buf_set_extmark(bufnr, NS, new_end, 0, {
            id = cs.output_mark,
            virt_lines = details.virt_lines,
            virt_lines_above = false,
            priority = 90,
          })
        end
      end
    end

    ::continue::
  end
end

--- Sync each valid cell's source from the current buffer into the notebook
--- model. Called before structural integrity checks so rebuilt cells carry
--- the latest edits.
---@param bufnr integer
---@param active_idx integer|nil  1-based index of the cell being edited.
---   When provided only that cell is synced (O(1) instead of O(n)).
---   Pass nil to sync all cells (used at save time).
function M.sync_sources_from_buf(bufnr, active_idx)
  local state = get_state(bufnr)
  local nb = state.notebook
  if not state or not nb or #state.cells == 0 then
    return
  end
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  -- When the active cell is known, only sync that one cell - O(1) extmark
  -- reads per keystroke instead of O(n).  The full sync path (nil) is kept
  -- for save and any caller that needs all cells current.
  local cells_to_sync
  if active_idx then
    local cs = state.cells[active_idx]
    cells_to_sync = cs and { cs } or {}
  else
    cells_to_sync = state.cells
  end

  for _, cs in ipairs(cells_to_sync) do
    local sm = vim.api.nvim_buf_get_extmark_by_id(bufnr, NS, cs.start_mark, {})
    if sm and #sm > 0 and sm[1] < line_count and nb.cells[cs.index] then
      local s = sm[1]
      local em = vim.api.nvim_buf_get_extmark_by_id(bufnr, NS, cs.end_mark, {})
      local e = (em and #em > 0) and em[1] or s
      e = math.min(e, line_count - 1)
      local lines = vim.api.nvim_buf_get_lines(bufnr, s, e + 1, false)
      nb.cells[cs.index].source = table.concat(lines, "\n")
    end
  end
end

--- Detect and recover from structural undo (undoing add_cell / delete_cell).
---
--- When undo reverts the buffer lines written by render(), state.cells and
--- notebook.cells still reflect the post-operation count. This function counts
--- cells whose start_mark is within the current buffer length. If that count
--- is less than #state.cells, structural divergence has occurred: notebook.cells
--- is rebuilt from the valid cells (with sources read from the buffer) and a
--- full re-render is scheduled.
---
--- A blank-buffer edge case (line_count == 0) is handled separately: the
--- current notebook model is re-rendered without rebuilding cells.
---@param bufnr integer
function M.check_structural_integrity(bufnr)
  if _integrity_guard[bufnr] then
    return
  end
  local state = get_state(bufnr)
  if not state or #state.cells == 0 then
    return
  end
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local nb = state.notebook
  if not nb then
    return
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)

  -- Blank buffer: all of render()'s set_lines were undone. Re-render to restore.
  if line_count == 0 then
    _integrity_guard[bufnr] = true
    vim.schedule(function()
      _integrity_guard[bufnr] = nil
      if vim.api.nvim_buf_is_valid(bufnr) then
        M.render(bufnr, nb)
      end
    end)
    return
  end

  -- Count cells whose start_mark is still within the buffer.
  local valid_count = 0
  for _, cs in ipairs(state.cells) do
    local sm = vim.api.nvim_buf_get_extmark_by_id(bufnr, NS, cs.start_mark, {})
    if sm and #sm > 0 and sm[1] < line_count then
      valid_count = valid_count + 1
    end
  end

  if valid_count == #state.cells then
    return -- no structural divergence
  end

  -- Structural divergence: rebuild notebook.cells from only the valid cells,
  -- reading their current source from the buffer.
  local new_cells = {}
  for _, cs in ipairs(state.cells) do
    local sm = vim.api.nvim_buf_get_extmark_by_id(bufnr, NS, cs.start_mark, {})
    if sm and #sm > 0 and sm[1] < line_count then
      local s = sm[1]
      local em = vim.api.nvim_buf_get_extmark_by_id(bufnr, NS, cs.end_mark, {})
      local e = (em and #em > 0) and em[1] or s
      e = math.min(e, line_count - 1)
      local lines = vim.api.nvim_buf_get_lines(bufnr, s, e + 1, false)
      local orig = nb.cells[cs.index]
      if orig then
        local rebuilt = {}
        for k, v in pairs(orig) do
          rebuilt[k] = v
        end
        rebuilt.source = table.concat(lines, "\n")
        new_cells[#new_cells + 1] = rebuilt
      end
    end
  end

  if #new_cells == 0 then
    return
  end

  nb.cells = new_cells
  _integrity_guard[bufnr] = true
  vim.schedule(function()
    _integrity_guard[bufnr] = nil
    if vim.api.nvim_buf_is_valid(bufnr) then
      M.render(bufnr, nb)
    end
  end)
end

--- Return the namespace id (used by other modules that add extmarks).
---@return integer
function M.namespace()
  return NS
end

return M
