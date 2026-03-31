--- ipynb.ui.image
--- Image rendering for cell output using image.nvim.
---
--- image.nvim (github.com/3rd/image.nvim) is an optional dependency.
--- If it is not installed the module falls back to a text placeholder.
---
--- Images are rendered directly into the source window using image.nvim's
--- native positioning. The y-coordinate is set to the separator line
--- (end_row + 1), which is a real buffer line placed AFTER all virt_lines,
--- so screenpos() naturally returns the correct screen row. This avoids
--- float windows and all associated visual artefacts (black rectangles,
--- misalignment, tmux pane bleed).
---
--- Public API:
---   image.render(bufnr, cell_state, chunk) -> boolean
---   image.clear(bufnr, cell_state)
---   image.clear_all(bufnr, cells)
---   image.rerender_all(bufnr)
---   image.is_supported() -> boolean

local M = {}

-- ── Per-cell image registry ───────────────────────────────────────────────────
-- Key:   bufnr .. ":" .. cell_state.start_mark
-- Value: list of {
--   img        : image.nvim object
--   tmp        : string   temp file path
--   end_row    : integer  0-based buffer row of the separator line
--   source_win : integer  main buffer window
-- }
local _registry = {}

local function cell_key(bufnr, cs)
  return tostring(bufnr) .. ":" .. tostring(cs.start_mark)
end

-- ── Support detection ─────────────────────────────────────────────────────────

---@return boolean
function M.is_supported()
  local cfg = require("ipynb.config").get()
  if not cfg.image.enabled then
    return false
  end
  return require("ipynb.utils").has_plugin("image")
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

local function chunk_to_tmp(chunk)
  local mime = chunk.mime or "image/png"
  local data = chunk.data or ""
  if mime == "image/png" then
    return write_b64_to_tmp(data, "png"), "png"
  elseif mime == "image/jpeg" then
    return write_b64_to_tmp(data, "jpg"), "jpg"
  elseif mime == "image/svg+xml" then
    local svg = data
    if type(svg) == "table" then
      svg = table.concat(svg)
    end
    return write_svg_to_tmp(svg), "svg"
  end
  return nil, nil
end

-- ── Rendering ─────────────────────────────────────────────────────────────────

--- Render one image chunk below a cell's text output.
---
--- The image is placed at y = sep_row + img_index * max_height, where sep_row
--- is end_row + 1 (the real buffer line after all virt_lines).  img_index (0
--- for the first image, 1 for the second, etc.) stacks multiple images from
--- the same cell vertically so they do not overlap.
---
---@param bufnr integer
---@param cell_state table
---@param chunk table    { type="image", mime, data }
---@param img_index integer  0-based position among images in this cell (default 0)
---@return boolean  true if image object was created
function M.render(bufnr, cell_state, chunk, img_index)
  if not M.is_supported() then
    return false
  end

  local ok_api, image_api = pcall(require, "image")
  if not ok_api then
    return false
  end

  img_index = img_index or 0

  local cfg = require("ipynb.config").get()
  local cell_mod = require("ipynb.core.cell")
  local utils = require("ipynb.utils")

  local tmp = chunk_to_tmp(chunk)
  if not tmp then
    utils.debug("image.lua: could not decode image payload (mime=" .. (chunk.mime or "?") .. ")")
    return false
  end

  -- Locate the cell's end_mark buffer row.
  local ns = cell_mod.namespace()
  local em_pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, cell_state.end_mark, {})
  local end_row = (em_pos and em_pos[1]) or 0
  local max_row = math.max(0, vim.api.nvim_buf_line_count(bufnr) - 1)
  end_row = math.min(end_row, max_row)

  -- sep_row is the real buffer line after all virt_lines; screenpos() on it
  -- returns the terminal row directly below the output block.
  -- Each subsequent image is offset by max_height rows so they stack vertically.
  local sep_row = math.min(end_row + 1, max_row)
  local y = sep_row + img_index * cfg.image.max_height

  local source_win = vim.fn.bufwinid(bufnr)
  if source_win == -1 then
    source_win = vim.api.nvim_get_current_win()
  end

  -- Viewport guard: if this image's row is below the visible window bottom,
  -- register without rendering so rerender_all() picks it up on scroll.
  local info = vim.fn.getwininfo(source_win)
  if info and info[1] then
    local botline = info[1].botline -- 1-based
    if y + 1 > botline then
      local key = cell_key(bufnr, cell_state)
      if not _registry[key] then
        _registry[key] = {}
      end
      _registry[key][#_registry[key] + 1] = {
        img = nil,
        tmp = tmp,
        end_row = end_row,
        img_index = img_index,
        source_win = source_win,
        chunk = chunk,
      }
      return true
    end
  end

  local key = cell_key(bufnr, cell_state)
  if not _registry[key] then
    _registry[key] = {}
  end

  local img_id = "ipynb_" .. key:gsub(":", "_") .. "_" .. tostring(img_index)

  local img
  local ok_from
  ok_from, img = pcall(image_api.from_file, tmp, {
    id = img_id,
    buffer = bufnr,
    window = source_win,
    x = 2,
    y = y,
    width = cfg.image.max_width,
    height = cfg.image.max_height,
    with_virtual_padding = true,
  })
  if not ok_from then
    utils.debug("image.nvim from_file error: " .. tostring(img))
    os.remove(tmp)
    return false
  end

  _registry[key][#_registry[key] + 1] = {
    img = img,
    tmp = tmp,
    end_row = end_row,
    img_index = img_index,
    source_win = source_win,
    chunk = chunk,
  }

  local ok_render, render_err = pcall(function()
    img:render()
  end)
  if not ok_render then
    utils.debug("image.nvim render error (will retry on scroll): " .. tostring(render_err))
  end

  return true
end

-- ── Scroll re-render ─────────────────────────────────────────────────────────

--- Re-render / reposition all registered images for a buffer.
--- Called from the WinScrolled debounce.
---@param bufnr integer
function M.rerender_all(bufnr)
  if not M.is_supported() then
    return
  end
  local cfg = require("ipynb.config").get()
  local ok_api, image_api = pcall(require, "image")
  if not ok_api then
    return
  end

  local prefix = tostring(bufnr) .. ":"
  for key, entries in pairs(_registry) do
    if key:sub(1, #prefix) ~= prefix then
      goto next_key
    end

    for _, entry in ipairs(entries) do
      local source_win = entry.source_win
      if not source_win or not vim.api.nvim_win_is_valid(source_win) then
        goto next_entry
      end

      local max_row = math.max(0, vim.api.nvim_buf_line_count(bufnr) - 1)
      local sep_row = math.min(entry.end_row + 1, max_row)
      local y = sep_row + (entry.img_index or 0) * cfg.image.max_height

      -- Viewport guard: skip images whose row is fully off-screen.
      local info = vim.fn.getwininfo(source_win)
      if not info or not info[1] then
        goto next_entry
      end
      local botline = info[1].botline
      if y + 1 > botline then
        -- Image scrolled off-screen: clear to prevent tmux bleed.
        if entry.img then
          pcall(function()
            entry.img:clear()
          end)
          entry.img = nil
        end
        goto next_entry
      end

      -- Image is visible. If no live image object, create one now.
      if not entry.img then
        if not entry.tmp or vim.fn.filereadable(entry.tmp) == 0 then
          goto next_entry
        end
        local idx = entry.img_index or 0
        local img_id = "ipynb_retry_" .. key:gsub(":", "_") .. "_" .. tostring(idx)
        local ok_from, img2 = pcall(image_api.from_file, entry.tmp, {
          id = img_id,
          buffer = bufnr,
          window = source_win,
          x = 2,
          y = y,
          width = cfg.image.max_width,
          height = cfg.image.max_height,
          with_virtual_padding = true,
        })
        if ok_from then
          entry.img = img2
          pcall(function()
            img2:render()
          end)
        end
        goto next_entry
      end

      -- Live image: re-render to update position after scroll.
      pcall(function()
        entry.img:render()
      end)

      ::next_entry::
    end
    ::next_key::
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
    if entry.img then
      pcall(function()
        entry.img:clear()
      end)
    end
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
---@param chunk table
---@return string
function M.placeholder(chunk)
  local mime = (chunk.mime or "image/png"):gsub("image/", "")
  return string.format("  [%s image - install image.nvim for rendering]", mime)
end

return M
