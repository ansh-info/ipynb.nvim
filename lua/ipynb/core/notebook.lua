--- ipynb.core.notebook
--- Parses .ipynb JSON files into an internal notebook data structure,
--- renders cells into a Neovim buffer, and serialises changes back to disk.
---
--- Notebook data model:
---
---   Notebook = {
---     path      : string,           -- absolute path on disk
---     nbformat  : integer,          -- nbformat version (3 or 4)
---     metadata  : table,            -- raw notebook-level metadata
---     cells     : Cell[],           -- ordered list of cells
---   }
---
---   Cell = {
---     id         : string,          -- nbformat 4.5 cell id, or generated
---     cell_type  : "code"|"markdown"|"raw",
---     source     : string,          -- raw source text (joined lines)
---     outputs    : Output[],        -- cell outputs (code cells only)
---     metadata   : table,
---     execution_count : integer|nil,
---   }

local utils = require("ipynb.utils")

local M = {}

-- ── Internal helpers ─────────────────────────────────────────────────────────

--- Join a "source" field from the nbformat (either a string or a list of strings).
---@param src string|string[]
---@return string
local function join_source(src)
  if type(src) == "string" then
    return src
  end
  return table.concat(src, "")
end

--- Generate a simple cell id when the notebook omits one (pre-4.5 formats).
---@return string
local function gen_cell_id()
  return string.format("%08x", math.random(0, 0xFFFFFFFF))
end

-- ── Parsing ───────────────────────────────────────────────────────────────────

--- Parse a raw notebook JSON table into the internal Notebook structure.
--- Returns nil and an error string on failure.
---@param raw table  Decoded JSON table from vim.json.decode
---@param path string
---@return table|nil notebook, string|nil err
function M.parse(raw, path)
  local nbformat = raw.nbformat or 4
  if nbformat < 3 then
    return nil, "unsupported nbformat version: " .. tostring(nbformat)
  end

  -- nbformat 3 uses "worksheets"; flatten to a single cell list.
  local raw_cells = raw.cells
  if not raw_cells and raw.worksheets then
    raw_cells = {}
    for _, ws in ipairs(raw.worksheets) do
      for _, cell in ipairs(ws.cells or {}) do
        raw_cells[#raw_cells + 1] = cell
      end
    end
  end
  raw_cells = raw_cells or {}

  local cells = {}
  for _, rc in ipairs(raw_cells) do
    local cell = {
      id = rc.id or gen_cell_id(),
      cell_type = rc.cell_type or "code",
      source = join_source(rc.source or ""),
      outputs = rc.outputs or {},
      metadata = rc.metadata or {},
      execution_count = rc.execution_count,
    }
    cells[#cells + 1] = cell
  end

  local notebook = {
    path = path,
    nbformat = nbformat,
    nbformat_minor = raw.nbformat_minor or 5,
    metadata = raw.metadata or {},
    cells = cells,
  }
  return notebook, nil
end

--- Load and parse a .ipynb file from disk.
---@param path string
---@return table|nil notebook, string|nil err
function M.load(path)
  local content, err = utils.read_file(path)
  if not content then
    return nil, "cannot read file: " .. (err or path)
  end

  local ok, raw = pcall(vim.json.decode, content)
  if not ok then
    return nil, "invalid JSON in notebook: " .. tostring(raw)
  end

  return M.parse(raw, path)
end

-- ── Serialisation ─────────────────────────────────────────────────────────────

--- Convert the internal Notebook structure back to nbformat 4 JSON and write
--- to disk.
---@param notebook table
---@return boolean ok, string|nil err
function M.save(notebook)
  -- Build cell list in nbformat 4 layout.
  local raw_cells = {}
  for _, cell in ipairs(notebook.cells) do
    -- Split source into lines (nbformat stores source as a list of strings
    -- with "\n" preserved at the end of each line, except the last).
    local lines = vim.split(cell.source, "\n", { plain = true })
    local source_lines = {}
    for i, line in ipairs(lines) do
      source_lines[i] = (i < #lines) and (line .. "\n") or line
    end

    local rc = {
      id = cell.id,
      cell_type = cell.cell_type,
      source = source_lines,
      metadata = cell.metadata or {},
    }
    if cell.cell_type == "code" then
      rc.outputs = cell.outputs or {}
      rc.execution_count = cell.execution_count
    end
    raw_cells[#raw_cells + 1] = rc
  end

  local raw = {
    nbformat = notebook.nbformat or 4,
    nbformat_minor = notebook.nbformat_minor or 5,
    metadata = notebook.metadata or {},
    cells = raw_cells,
  }

  local ok_enc, json = pcall(vim.json.encode, raw)
  if not ok_enc then
    return false, "JSON encoding failed: " .. tostring(json)
  end

  -- Pretty-print: vim.json.encode produces compact JSON; decode + re-encode
  -- is not available in all Neovim versions, so we leave it compact.
  -- Users can run `python3 -m json.tool` externally if they want indented output.
  local ok_write, werr = utils.write_file(notebook.path, json)
  if not ok_write then
    return false, "cannot write file: " .. (werr or notebook.path)
  end

  return true, nil
end

-- ── Buffer → Notebook sync ────────────────────────────────────────────────────

--- Read the current buffer lines for a cell (identified by its line range)
--- and update cell.source in the notebook.
---@param notebook table
---@param cell_index integer  1-based index into notebook.cells
---@param bufnr integer
---@param start_line integer  0-based first line of cell content
---@param end_line integer    0-based last line (exclusive) of cell content
function M.sync_cell_from_buffer(notebook, cell_index, bufnr, start_line, end_line)
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
  notebook.cells[cell_index].source = table.concat(lines, "\n")
end

--- Kernel name from notebook metadata (falls back to "python3").
---@param notebook table
---@return string
function M.kernel_name(notebook)
  local ks = (notebook.metadata or {}).kernelspec
  if ks and ks.name then
    return ks.name
  end
  return "python3"
end

--- Code language for the notebook (from kernelspec / language_info metadata).
--- Used to set the buffer filetype so treesitter and LSP match the kernel.
---@param notebook table
---@return string
function M.notebook_language(notebook)
  local ks = (notebook.metadata or {}).kernelspec
  if ks and ks.language then
    return ks.language
  end
  local li = (notebook.metadata or {}).language_info
  if li and li.name then
    return li.name
  end
  return "python"
end

--- Language name for a cell (looks at notebook kernelspec metadata).
---@param notebook table
---@param cell table
---@return string
function M.cell_language(notebook, cell)
  if cell.cell_type == "markdown" then
    return "markdown"
  end
  if cell.cell_type == "raw" then
    return "raw"
  end

  local ks = (notebook.metadata or {}).kernelspec
  if ks and ks.language then
    return ks.language
  end

  local li = (notebook.metadata or {}).language_info
  if li and li.name then
    return li.name
  end

  return "python"
end

M.gen_cell_id = gen_cell_id

return M
