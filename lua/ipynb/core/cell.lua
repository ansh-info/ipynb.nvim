--- ipynb.cell
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
function M.render(bufnr, notebook)
  define_highlights()

  local state = get_state(bufnr)
  state.notebook = notebook
  state.cells = {}

  -- Unlock the buffer for writing.
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_option(bufnr, "readonly", false)

  -- Clear everything.
  vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})

  local win_width = vim.api.nvim_win_get_width(0)

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

    -- Advance: add a blank separator line between cells (not after the last).
    current_line = end_line + 1
    if i < #notebook.cells then
      vim.api.nvim_buf_set_lines(bufnr, current_line, current_line, false, { "" })
      current_line = current_line + 1
    end
  end

  -- Lock filetype for syntax highlighting.
  vim.api.nvim_buf_set_option(bufnr, "filetype", "python")

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

--- Add a new empty code cell below the cell at `idx`.
---@param bufnr integer
---@param idx integer  1-based index of the reference cell
function M.add_cell_below(bufnr, idx)
  local state = get_state(bufnr)
  local notebook = state.notebook
  if not notebook then
    return
  end

  -- Insert a new empty cell into the notebook model.
  local new_cell = {
    id = require("ipynb.core.notebook").gen_cell_id
        and require("ipynb.core.notebook").gen_cell_id()
      or utils.uid(),
    cell_type = "code",
    source = "",
    outputs = {},
    metadata = {},
    execution_count = nil,
  }
  table.insert(notebook.cells, idx + 1, new_cell)

  -- Re-render the whole buffer to reflect the new cell.
  M.render(bufnr, notebook)

  -- Position cursor in the new cell.
  local new_cs = state.cells[idx + 1]
  if new_cs then
    local s, _ = cell_line_range(bufnr, new_cs)
    vim.api.nvim_win_set_cursor(0, { s + 1, 0 })
    vim.cmd("startinsert")
  end
end

--- Add a new empty code cell above the cell at `idx`.
---@param bufnr integer
---@param idx integer
function M.add_cell_above(bufnr, idx)
  local state = get_state(bufnr)
  local notebook = state.notebook
  if not notebook then
    return
  end

  local new_cell = {
    id = utils.uid(),
    cell_type = "code",
    source = "",
    outputs = {},
    metadata = {},
    execution_count = nil,
  }
  table.insert(notebook.cells, idx, new_cell)

  M.render(bufnr, notebook)

  local new_cs = state.cells[idx]
  if new_cs then
    local s, _ = cell_line_range(bufnr, new_cs)
    vim.api.nvim_win_set_cursor(0, { s + 1, 0 })
    vim.cmd("startinsert")
  end
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
  M.render(bufnr, notebook)
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

  local win_width = vim.api.nvim_win_get_width(0)
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

  local win_width = vim.api.nvim_win_get_width(0)
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
function M.reanchor_end_marks(bufnr)
  local state = get_state(bufnr)
  if not state or #state.cells == 0 then
    return
  end
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local win_width = vim.api.nvim_win_get_width(0)

  for i, cs in ipairs(state.cells) do
    local sm = vim.api.nvim_buf_get_extmark_by_id(bufnr, NS, cs.start_mark, {})
    if not sm or #sm == 0 then
      goto continue
    end
    local start_row = sm[1]

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

--- Return the namespace id (used by other modules that add extmarks).
---@return integer
function M.namespace()
  return NS
end

return M
