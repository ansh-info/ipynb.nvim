--- ipynb.ui.image
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
  if not cfg.image.enabled then
    return false
  end
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
  -- Write the base64 payload to an intermediate file so we avoid shell
  -- argument-length limits (large plots can exceed ARG_MAX on some systems).
  local b64_tmp = vim.fn.tempname() .. ".b64"
  local f = io.open(b64_tmp, "w")
  if not f then
    return nil
  end
  f:write(b64)
  f:close()
  -- macOS base64 uses -D for decode; Linux uses -d.  Try both.
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

--- Write raw SVG text to a temporary file.
---@param svg_text string
---@return string|nil path
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
---@param bufnr integer
---@param cell_state table
---@param chunk table   { type="image", mime, data }
---@return boolean  true if image was rendered
function M.render(bufnr, cell_state, chunk)
  if not M.is_supported() then
    return false
  end

  local ok_api, image_api = pcall(require, "image")
  if not ok_api then
    return false
  end

  local cfg = require("ipynb.config").get()
  local cell = require("ipynb.core.cell")
  local utils = require("ipynb.utils")

  -- Write image data to a temp file.
  local tmp = chunk_to_tmp(chunk)
  if not tmp then
    utils.debug("image.lua: could not decode image payload (mime=" .. (chunk.mime or "?") .. ")")
    return false
  end

  -- Find the buffer line where the cell ends (the end_mark line).
  -- Clamp to the current buffer length so a stale extmark after undo never
  -- causes E966 "Invalid line number" in image.nvim's screenpos() call.
  local ns = cell.namespace()
  local em_pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, cell_state.end_mark, {})
  local end_row = (em_pos and em_pos[1]) or 0
  local max_row = math.max(0, vim.api.nvim_buf_line_count(bufnr) - 1)
  end_row = math.min(end_row, max_row)

  -- Get the window showing this buffer (prefer current window).
  local winnr = vim.fn.bufwinid(bufnr)
  if winnr == -1 then
    winnr = 0
  end

  -- Guard against rendering below the visible window area, which causes the
  -- image to bleed into adjacent tmux panes. Skip rendering if end_row is
  -- below the last visible line of the window.
  local win_info = vim.fn.getwininfo(winnr == 0 and vim.api.nvim_get_current_win() or winnr)
  if win_info and win_info[1] then
    local bot_line = win_info[1].botline -- last visible buffer line (1-based)
    if end_row + 1 > bot_line then
      os.remove(tmp)
      return
    end
  end

  -- Build a unique id for this image instance.
  local key = cell_key(bufnr, cell_state)
  local img_id = "ipynb_" .. key:gsub(":", "_") .. "_" .. tostring(os.time())

  local img
  ok_api, img = pcall(image_api.from_file, tmp, {
    id = img_id,
    buffer = bufnr,
    window = winnr,
    x = 2,
    y = end_row,
    width = cfg.image.max_width,
    height = cfg.image.max_height,
    with_virtual_padding = true,
  })

  if not ok_api then
    utils.debug("image.nvim from_file error: " .. tostring(img))
    os.remove(tmp)
    return false
  end

  -- Register before rendering so WinScrolled can retry if the initial
  -- render fails because the cell output is off-screen (screenpos = 0,0).
  if not _registry[key] then
    _registry[key] = {}
  end
  _registry[key][#_registry[key] + 1] = { img = img, tmp = tmp }

  local ok_render, render_err = pcall(function()
    img:render()
  end)
  if not ok_render then
    utils.debug("image.nvim render error (will retry on scroll): " .. tostring(render_err))
  end

  return true
end

-- ── Scroll re-render ─────────────────────────────────────────────────────────

--- Re-render all registered images for a buffer.
--- Called from the WinScrolled autocmd so images follow the viewport and
--- any image whose initial render failed (output was off-screen) gets retried.
---@param bufnr integer
function M.rerender_all(bufnr)
  if not M.is_supported() then
    return
  end
  local prefix = tostring(bufnr) .. ":"
  for key, entries in pairs(_registry) do
    if key:sub(1, #prefix) == prefix then
      for _, entry in ipairs(entries) do
        pcall(function()
          entry.img:render()
        end)
      end
    end
  end
end

-- ── Cleanup ───────────────────────────────────────────────────────────────────

--- Clear all rendered images for a single cell.
---@param bufnr integer
---@param cell_state table
function M.clear(bufnr, cell_state)
  local key = cell_key(bufnr, cell_state)
  local entries = _registry[key]
  if not entries then
    return
  end
  for _, entry in ipairs(entries) do
    pcall(function()
      entry.img:clear()
    end)
    if entry.tmp then
      pcall(os.remove, entry.tmp)
    end
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
