--- ipynb.ui.image
--- Image rendering for cell output using snacks.nvim placements.
---
--- snacks.nvim (folke/snacks.nvim) renders images via Kitty unicode
--- placeholders embedded as virtual text.  Placements move with the buffer
--- automatically - no WinScrolled re-render, no viewport guard, no ImageMagick.
---
--- Required: snacks.nvim with image support enabled, terminal with Kitty
--- graphics protocol unicode placeholder support (kitty 0.28+, Ghostty, WezTerm).
---
--- Public API:
---   image.is_supported()                    -> boolean
---   image.render(bufnr, cell_state, chunks) -> boolean
---   image.clear(bufnr, cell_state)
---   image.clear_all(bufnr, cells)
---   image.placeholder(chunk)                -> string

local M = {}

-- ── Per-cell placement registry ───────────────────────────────────────────────
-- Key:   tostring(bufnr) .. ":" .. tostring(cell_state.start_mark)
-- Value: list of { placement: snacks Placement object, tmp: string path }
local _placements = {}

local function cell_key(bufnr, cs)
  return tostring(bufnr) .. ":" .. tostring(cs.start_mark)
end

-- ── Support detection ─────────────────────────────────────────────────────────

--- Return true when snacks.nvim image placement is available AND the terminal
--- supports Kitty unicode placeholders.
---@return boolean
function M.is_supported()
  local cfg = require("ipynb.config").get()
  if not cfg.image.enabled then
    return false
  end
  local ok_p = pcall(require, "snacks.image.placement")
  if not ok_p then
    return false
  end
  local ok_t, terminal = pcall(require, "snacks.image.terminal")
  if not ok_t then
    return false
  end
  local ok_e, env = pcall(function()
    return terminal.env()
  end)
  return ok_e and env ~= nil and env.placeholders == true
end

-- ── Temp file helpers ─────────────────────────────────────────────────────────

local function write_b64_to_tmp(b64, ext)
  local tmp = vim.fn.tempname() .. "." .. ext
  local b64_tmp = vim.fn.tempname() .. ".b64"
  local f = io.open(b64_tmp, "w")
  if not f then
    return nil
  end
  f:write(b64)
  f:close()
  -- Support both GNU base64 (-d) and macOS base64 (-D).
  local cmd = string.format(
    "base64 -d < %s > %s 2>/dev/null || base64 -D < %s > %s 2>/dev/null",
    vim.fn.shellescape(b64_tmp),
    vim.fn.shellescape(tmp),
    vim.fn.shellescape(b64_tmp),
    vim.fn.shellescape(tmp)
  )
  vim.fn.system(cmd)
  os.remove(b64_tmp)
  if vim.fn.filereadable(tmp) == 1 and vim.fn.getfsize(tmp) > 0 then
    return tmp
  end
  return nil
end

local function write_svg_to_tmp(svg_text)
  local tmp = vim.fn.tempname() .. ".svg"
  local f = io.open(tmp, "w")
  if not f then
    return nil
  end
  f:write(svg_text)
  f:close()
  return tmp
end

--- Decode one image output chunk to a temp file.
--- Returns the file path, or nil if decoding fails.
---@param chunk table  { type="image", mime, data }
---@return string|nil
local function chunk_to_tmp(chunk)
  local mime = chunk.mime or "image/png"
  local data = chunk.data or ""
  if mime == "image/png" then
    return write_b64_to_tmp(data, "png")
  elseif mime == "image/jpeg" then
    return write_b64_to_tmp(data, "jpg")
  elseif mime == "image/svg+xml" then
    local svg = data
    if type(svg) == "table" then
      svg = table.concat(svg)
    end
    return write_svg_to_tmp(svg)
  end
  return nil
end

-- ── Rendering ─────────────────────────────────────────────────────────────────

--- Render all image chunks for a cell using snacks.nvim Placement objects.
---
--- Each chunk becomes its own Placement anchored at end_row.  Multiple
--- placements at the same row have their virt_lines appended in creation order,
--- so images stack naturally below the cell without any coordinate arithmetic.
--- snacks handles scroll sync and resize via auto_resize = true - no WinScrolled
--- autocmd or rerender_all logic is required on our side.
---
---@param bufnr integer
---@param cell_state table
---@param chunks table[]  list of { type="image", mime, data } chunks
---@return boolean  true if at least one placement was created
function M.render(bufnr, cell_state, chunks)
  if not M.is_supported() then
    return false
  end
  if not chunks or #chunks == 0 then
    return false
  end

  local ok_p, Placement = pcall(require, "snacks.image.placement")
  if not ok_p then
    return false
  end

  local cfg = require("ipynb.config").get()
  local cell_mod = require("ipynb.core.cell")
  local utils = require("ipynb.utils")

  -- Locate the cell end_mark buffer row (0-indexed).
  local ns = cell_mod.namespace()
  local em_pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, cell_state.end_mark, {})
  local end_row = (em_pos and em_pos[1]) or 0
  local max_row = math.max(0, vim.api.nvim_buf_line_count(bufnr) - 1)
  end_row = math.min(end_row, max_row)

  -- snacks pos is {row, col} with 1-indexed row.
  -- Place images at the row immediately after end_mark (clamped to buffer end).
  local base_row = math.min(end_row + 2, max_row + 1)

  local key = cell_key(bufnr, cell_state)
  if not _placements[key] then
    _placements[key] = {}
  end

  local created = false
  for _, chunk in ipairs(chunks) do
    local tmp = chunk_to_tmp(chunk)
    if not tmp then
      utils.debug("image.lua: could not decode chunk mime=" .. (chunk.mime or "?"))
    else
      -- All images anchor at base_row; snacks appends each placement's virt_lines
      -- below the previous one in creation order, giving natural stacking.
      local ok_new, placement = pcall(Placement.new, bufnr, tmp, {
        pos = { base_row, 0 },
        inline = true,
        auto_resize = true,
        max_width = cfg.image.max_width,
        max_height = cfg.image.max_height,
      })
      if not ok_new then
        utils.debug("snacks Placement.new error: " .. tostring(placement))
        pcall(os.remove, tmp)
      else
        _placements[key][#_placements[key] + 1] = { placement = placement, tmp = tmp }
        created = true
      end
    end
  end

  return created
end

-- ── Cleanup ───────────────────────────────────────────────────────────────────

--- Close all placements and remove temp files for a single cell.
---@param bufnr integer
---@param cell_state table
function M.clear(bufnr, cell_state)
  local key = cell_key(bufnr, cell_state)
  local entries = _placements[key]
  if not entries then
    return
  end
  for _, entry in ipairs(entries) do
    if entry.placement then
      pcall(function()
        entry.placement:close()
      end)
    end
    if entry.tmp then
      pcall(os.remove, entry.tmp)
    end
  end
  _placements[key] = nil
end

--- Close all placements for every cell in a buffer (kernel restart / buf wipe).
---@param bufnr integer
---@param cells table[]
function M.clear_all(bufnr, cells)
  for _, cs in ipairs(cells or {}) do
    M.clear(bufnr, cs)
  end
end

--- Return a human-readable placeholder string for unsupported environments.
---@param chunk table
---@return string
function M.placeholder(chunk)
  local mime = (chunk.mime or "image/png"):gsub("image/", "")
  return string.format("  [%s image - snacks.nvim + unicode placeholders required]", mime)
end

return M
