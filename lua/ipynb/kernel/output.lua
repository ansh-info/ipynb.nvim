--- ipynb.output
--- Converts raw Jupyter output chunks into Neovim virt_lines and renders
--- them below the cell that produced them.
---
--- Chunk types (mirrors kernel_bridge.py protocol):
---   { type = "stream",  name = "stdout"|"stderr", text = "..." }
---   { type = "result",  text = "...", html = "..." }
---   { type = "error",   ename = "...", evalue = "...", traceback = {...} }
---   { type = "image",   mime = "image/png", data = "<b64>" }
---   { type = "clear_output" }
---
--- Public API:
---   output.append(bufnr, cell_state, chunk)   -- add one chunk, re-render
---   output.clear(bufnr, cell_state)            -- wipe all output for a cell
---   output.get_chunks(cell_key)                -- return accumulated chunk list

local config = require("ipynb.config")
local cell = require("ipynb.core.cell")

local M = {}

-- ── Highlight groups ──────────────────────────────────────────────────────────
-- Defined in cell.lua define_highlights(); referenced by name here.
local HL = {
  text = "IpynbOutputText",
  result = "IpynbOutputResult",
  error = "IpynbOutputError",
  trace = "IpynbOutputErrorTrace",
  stderr = "DiagnosticWarn",
  divider = "IpynbCellBorder",
  meta = "IpynbOutputMeta",
  image = "IpynbOutputMeta",
}

-- ── Per-cell output accumulator ───────────────────────────────────────────────
-- Key: bufnr .. ":" .. cell_state.start_mark   (unique per cell per buffer)
-- Value: list of chunk tables
local _store = {}

-- ── Re-entrancy guards for image rendering ────────────────────────────────────
-- image.nvim's magick_cli processor uses vim.wait() which runs the Neovim
-- event loop mid-render.  A second output.append() arriving during that window
-- would fire another vim.schedule callback that calls image.clear(), deleting
-- the temp PNG file the first magick process is still reading → crash + freeze.
--
-- _active  : cell_key → true while a vim.schedule render callback is executing.
-- _pending : cell_key → true when a re-render was requested during an active one.
--
-- When a callback sees _active, it sets _pending and returns without touching
-- image.clear().  Once the active render finishes it checks _pending and calls
-- M._render again so the latest chunks are always shown.
local _active = {}
local _pending = {}

local function cell_key(bufnr, cell_state)
  return tostring(bufnr) .. ":" .. tostring(cell_state.start_mark)
end

--- Return accumulated chunks for a cell (empty list if none).
---@param bufnr integer
---@param cell_state table
---@return table[]
function M.get_chunks(bufnr, cell_state)
  return _store[cell_key(bufnr, cell_state)] or {}
end

--- Wipe accumulated chunks, virt_lines, and any rendered images for a cell.
---@param bufnr integer
---@param cell_state table
function M.clear(bufnr, cell_state)
  _store[cell_key(bufnr, cell_state)] = nil
  cell.clear_output(bufnr, cell_state)
  local ok, image = pcall(require, "ipynb.ui.image")
  if ok then
    image.clear(bufnr, cell_state)
  end
end

-- ── Text → virt_lines conversion ──────────────────────────────────────────────

--- Split a multi-line string and convert each line into a virt_line chunk-list.
--- Respects config.ui.output_max_lines (0 = unlimited).
---@param text string
---@param hl string  highlight group for every line
---@param max_lines integer
---@return table[]  list of virt_line chunk-lists
local function text_to_virt_lines(text, hl, max_lines)
  local lines = vim.split(text, "\n", { plain = true })
  -- Drop trailing blank line that split() produces for text ending in "\n".
  if lines[#lines] == "" then
    table.remove(lines)
  end
  if #lines == 0 then
    return {}
  end

  local truncated = 0
  if max_lines > 0 and #lines > max_lines then
    truncated = #lines - max_lines
    lines = vim.list_slice(lines, 1, max_lines)
  end

  local vl = {}
  for _, line in ipairs(lines) do
    vl[#vl + 1] = { { line, hl } }
  end
  if truncated > 0 then
    vl[#vl + 1] = { { string.format("  … %d more lines (truncated)", truncated), HL.meta } }
  end
  return vl
end

--- Build a thin divider line used between output blocks.
---@return table  single virt_line chunk-list
local function divider()
  return { { "  " .. string.rep("·", 40), HL.divider } }
end

-- ── Chunk → virt_lines ────────────────────────────────────────────────────────

--- Convert a single output chunk into a list of virt_line chunk-lists.
---@param chunk table
---@param max_lines integer
---@return table[]
local function chunk_to_virt_lines(chunk, max_lines)
  local t = chunk.type

  if t == "stream" then
    local hl = (chunk.name == "stderr") and HL.stderr or HL.text
    return text_to_virt_lines(chunk.text or "", hl, max_lines)
  elseif t == "result" then
    return text_to_virt_lines(chunk.text or "", HL.result, max_lines)
  elseif t == "error" then
    local vl = {}
    -- Header line: ErrorType: message
    local header = (chunk.ename or "Error") .. ": " .. (chunk.evalue or "")
    vl[#vl + 1] = { { "  " .. header, HL.error } }
    -- Traceback lines (each may contain embedded newlines from ANSI stripping).
    for _, tb_line in ipairs(chunk.traceback or {}) do
      local sub = text_to_virt_lines(tb_line, HL.trace, 0)
      for _, vl_line in ipairs(sub) do
        vl[#vl + 1] = vl_line
      end
    end
    return vl
  elseif t == "image" then
    -- image.lua handles actual rendering; return empty here so the image
    -- chunks are tracked in the store but don't produce duplicate text lines.
    -- A placeholder is returned only when image.nvim is unavailable.
    local ok, image = pcall(require, "ipynb.ui.image")
    if ok and image.is_supported() then
      return {} -- image.lua renders it; no text virt_line needed
    end
    return { { { image.placeholder(chunk), HL.image } } }
  end
  return {}
end

-- ── Public API ────────────────────────────────────────────────────────────────

--- Append one output chunk for a cell and re-render all virt_lines.
---@param bufnr integer
---@param cell_state table
---@param chunk table
function M.append(bufnr, cell_state, chunk)
  -- Handle clear_output by wiping everything first.
  if chunk.type == "clear_output" then
    M.clear(bufnr, cell_state)
    return
  end

  local key = cell_key(bufnr, cell_state)
  if not _store[key] then
    _store[key] = {}
  end
  _store[key][#_store[key] + 1] = chunk

  M._render(bufnr, cell_state)
end

--- Re-render all accumulated chunks for a cell.
--- Text chunks → virt_lines via cell.set_output_virt_lines.
--- Image chunks → image.lua (positioned after the text block).
---@param bufnr integer
---@param cell_state table
function M._render(bufnr, cell_state)
  local cfg = config.get()
  local max_lines = cfg.ui.output_max_lines
  local chunks = M.get_chunks(bufnr, cell_state)
  local key = cell_key(bufnr, cell_state)
  if #chunks == 0 then
    cell.clear_output(bufnr, cell_state)
    return
  end

  local ok_img, image = pcall(require, "ipynb.ui.image")
  local img_supported = ok_img and image.is_supported()

  local all_vl = {} -- text virt_lines
  local img_queue = {} -- image chunks to render after text virt_lines are placed

  -- Top divider.
  all_vl[#all_vl + 1] = divider()

  for i, chunk in ipairs(chunks) do
    if chunk.type == "image" and img_supported then
      img_queue[#img_queue + 1] = chunk
    else
      local vl = chunk_to_virt_lines(chunk, max_lines)
      for _, line in ipairs(vl) do
        all_vl[#all_vl + 1] = line
      end
      if i < #chunks and #vl > 0 then
        all_vl[#all_vl + 1] = divider()
      end
    end
  end

  -- Render in the main event loop so extmarks and image positions are stable.
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end

    -- Guard against re-entrant renders.  image.nvim's magick_cli uses
    -- vim.wait() which runs the event loop while magick converts the PNG.
    -- A second output.append() during that window queues another vim.schedule
    -- callback that would call image.clear(), deleting the temp file the first
    -- magick process is still reading.  Instead, record the request as pending
    -- and let it run once the active render finishes.
    if _active[key] then
      _pending[key] = true
      return
    end
    _active[key] = true

    -- 1. Place text virt_lines.
    cell.set_output_virt_lines(bufnr, cell_state, all_vl)

    -- 2. Clear old images then render new ones below the text block.
    if ok_img then
      image.clear(bufnr, cell_state)
      for _, chunk in ipairs(img_queue) do
        image.render(bufnr, cell_state, chunk)
      end
    end

    _active[key] = nil

    -- If more output arrived while we were rendering, re-render now so the
    -- latest chunks (e.g. a second matplotlib figure) are always displayed.
    if _pending[key] then
      _pending[key] = nil
      M._render(bufnr, cell_state)
    end
  end)
end

--- Remove all stored output for every cell in a buffer (called on kernel restart).
---@param bufnr integer
---@param cells table[]
function M.clear_all(bufnr, cells)
  for _, cs in ipairs(cells or {}) do
    M.clear(bufnr, cs) -- M.clear() already handles images per cell
  end
end

return M
