--- ipynb.image
--- Image rendering for cell output using image.nvim.
---
--- image.nvim (github.com/3rd/image.nvim) is an optional dependency.
--- If it is not installed the module falls back to a text placeholder.
---
--- Supported backends (configured via image.nvim):
---   kitty     — Kitty graphics protocol (Kitty, Ghostty, WezTerm ≥ 0.5)
---   ueberzug  — ueberzugpp overlay (any X11/Wayland terminal)
---   sixel     — Sixel protocol (xterm, foot, WezTerm)
---
--- Flow:
---   output.lua calls image.render() for each image chunk after all text
---   virt_lines have been placed.  image.lua writes the payload to a temp
---   file, creates an image.nvim image object positioned below the cell,
---   and renders it with with_virtual_padding = true so the terminal
---   reserves the right amount of vertical space.
---
--- Public API:
---   image.render(bufnr, cell_state, chunk, text_line_offset) → boolean
---   image.clear(bufnr, cell_state)
---   image.clear_all(bufnr, cells)
---   image.is_supported() → boolean

local M = {}

-- ── Per-cell image registry ───────────────────────────────────────────────────
-- Key:   bufnr .. ":" .. cell_state.start_mark
-- Value: list of { img = <image.nvim object>, tmp = "/tmp/..." }
local _registry = {}

local function cell_key(bufnr, cs)
  return tostring(bufnr) .. ":" .. tostring(cs.start_mark)
end

-- ── Support detection ─────────────────────────────────────────────────────────

--- Return true if image rendering is available and enabled.
---@return boolean
function M.is_supported()
  local cfg = require("ipynb.config").get()
  if not cfg.image.enabled then return false end
  return require("ipynb.utils").has_plugin("image")
end

-- ── Temp file helpers ─────────────────────────────────────────────────────────

--- Write base64-encoded binary data to a temporary file.
--- Returns the file path, or nil on failure.
---@param b64 string  base64 payload (no newlines required)
---@param ext string  file extension, e.g. "png"
---@return string|nil path
local function write_b64_to_tmp(b64, ext)
  local tmp = vim.fn.tempname() .. "." .. ext
  -- Use the system base64 utility — reliable across platforms.
  local cmd = string.format(
    "printf '%%s' %s | base64 -d > %s",
    vim.fn.shellescape(b64),
    vim.fn.shellescape(tmp)
  )
  vim.fn.system(cmd)
  if vim.fn.filereadable(tmp) == 1 and vim.fn.getfsize(tmp) > 0 then
    return tmp
  end
  return nil
end

--- Write raw SVG text to a temporary file.
---@param svg_text string
---@return string|nil path
local function write_svg_to_tmp(svg_text)
  local tmp = vim.fn.tempname() .. ".svg"
  local f   = io.open(tmp, "w")
  if not f then return nil end
  f:write(svg_text)
  f:close()
  return tmp
end

--- Decode a chunk's image payload to a temp file.
--- Returns (tmp_path, ext) or (nil, nil) on failure.
---@param chunk table  { mime, data }
---@return string|nil, string|nil
local function chunk_to_tmp(chunk)
  local mime = chunk.mime or "image/png"
  local data = chunk.data or ""

  if mime == "image/png" then
    return write_b64_to_tmp(data, "png"), "png"
  elseif mime == "image/jpeg" then
    return write_b64_to_tmp(data, "jpg"), "jpg"
  elseif mime == "image/svg+xml" then
    -- SVG arrives as raw text, not base64.
    return write_svg_to_tmp(data), "svg"
  end
  return nil, nil
end

-- ── Rendering ─────────────────────────────────────────────────────────────────

--- Render one image chunk below a cell.
---
--- text_line_offset is the number of text virt_lines already placed above
--- this image so we can position the image correctly.
---
---@param bufnr integer
---@param cell_state table
---@param chunk table   { type="image", mime, data }
---@param text_line_offset integer  text virt_lines already above this image
---@return boolean  true if image was rendered
function M.render(bufnr, cell_state, chunk, text_line_offset)
  if not M.is_supported() then return false end

  local ok_api, image_api = pcall(require, "image")
  if not ok_api then return false end

  local cfg  = require("ipynb.config").get()
  local cell = require("ipynb.cell")
  local utils = require("ipynb.utils")

  -- Write image data to a temp file.
  local tmp, ext = chunk_to_tmp(chunk)
  if not tmp then
    utils.debug("image.lua: could not decode image payload (mime=" .. (chunk.mime or "?") .. ")")
    return false
  end

  -- Find the buffer line where the cell ends (the end_mark line).
  local ns      = cell.namespace()
  local em_pos  = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, cell_state.end_mark, {})
  local end_row = (em_pos and em_pos[1]) or 0

  -- y position: end of cell + 1 (bottom border virt_line) + divider + text lines
  -- All in 0-based terminal rows.
  local y = end_row + 1 + text_line_offset + 1

  -- Get the window showing this buffer (prefer current window).
  local winnr = vim.fn.bufwinid(bufnr)
  if winnr == -1 then winnr = 0 end

  -- Build a unique id for this image instance.
  local key    = cell_key(bufnr, cell_state)
  local img_id = "ipynb_" .. key:gsub(":", "_") .. "_" .. tostring(os.time())

  local img
  ok_api, img = pcall(image_api.from_file, tmp, {
    id     = img_id,
    buffer = bufnr,
    window = winnr,
    geometry = {
      x      = 2,
      y      = y,
      width  = cfg.image.max_width,
      height = cfg.image.max_height,
    },
    with_virtual_padding = true,
  })

  if not ok_api then
    utils.debug("image.nvim from_file error: " .. tostring(img))
    os.remove(tmp)
    return false
  end

  local ok_render, render_err = pcall(function() img:render() end)
  if not ok_render then
    utils.debug("image.nvim render error: " .. tostring(render_err))
    os.remove(tmp)
    return false
  end

  -- Track for cleanup.
  if not _registry[key] then _registry[key] = {} end
  _registry[key][#_registry[key] + 1] = { img = img, tmp = tmp }

  return true
end

-- ── Cleanup ───────────────────────────────────────────────────────────────────

--- Clear all rendered images for a single cell.
---@param bufnr integer
---@param cell_state table
function M.clear(bufnr, cell_state)
  local key     = cell_key(bufnr, cell_state)
  local entries = _registry[key]
  if not entries then return end
  for _, entry in ipairs(entries) do
    pcall(function() entry.img:clear() end)
    if entry.tmp then pcall(os.remove, entry.tmp) end
  end
  _registry[key] = nil
end

--- Clear all images for every cell in a buffer (used on kernel restart).
---@param bufnr integer
---@param cells table[]
function M.clear_all(bufnr, cells)
  for _, cs in ipairs(cells or {}) do
    M.clear(bufnr, cs)
  end
end

--- Return a human-readable placeholder string for unsupported environments.
--- Used by output.lua when image.nvim is not available.
---@param chunk table
---@return string
function M.placeholder(chunk)
  local mime = (chunk.mime or "image/png"):gsub("image/", "")
  return string.format("  [%s image — install image.nvim for rendering]", mime)
end

return M
