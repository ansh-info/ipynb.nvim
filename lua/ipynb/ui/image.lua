--- ipynb.ui.image
--- Image rendering for cell output using image.nvim.
---
--- image.nvim (github.com/3rd/image.nvim) is an optional dependency.
--- If it is not installed the module falls back to a text placeholder.
---
--- Each image is rendered into a dedicated floating window that is
--- positioned precisely below the cell's text output virt_lines. This:
---   - Clips images to the Neovim editor window (no tmux pane bleed)
---   - Positions images below all text virt_lines (no overlap with border)
---   - Repositions floats on scroll via nvim_win_set_config without a
---     clear+redraw cycle (less flicker)
---
--- Public API:
---   image.render(bufnr, cell_state, chunk, text_line_offset) -> boolean
---   image.clear(bufnr, cell_state)
---   image.clear_all(bufnr, cells)
---   image.rerender_all(bufnr)
---   image.is_supported() -> boolean

local M = {}

-- ── Per-cell image registry ───────────────────────────────────────────────────
-- Key:   bufnr .. ":" .. cell_state.start_mark
-- Value: list of {
--   img        : image.nvim object
--   tmp        : string   temp file path (kept alive for scroll re-render)
--   float_win  : integer|nil  floating window handle (nil = not yet shown)
--   float_buf  : integer|nil  scratch buffer for the float
--   end_row    : integer   0-based buffer row of the cell end_mark
--   text_offset: integer   text virt_lines (incl. dividers) above the image
--   source_win : integer   main buffer window
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

-- ── Float window helpers ──────────────────────────────────────────────────────

--- Compute the 0-based row for a float window relative to source_win.
--- Uses topline arithmetic so it is safe to call before Neovim redraws
--- (avoids the screenpos() timing issue inside vim.schedule callbacks).
--- Returns nil when the cell is off-screen.
---@param source_win integer
---@param end_row integer    0-based buffer row of the cell end_mark
---@param text_offset integer text virt_lines above the image (incl. dividers)
---@return integer|nil
local function float_row_approx(source_win, end_row, text_offset)
  local info = vim.fn.getwininfo(source_win)
  if not info or not info[1] then
    return nil
  end
  local topline = info[1].topline -- 1-based
  local botline = info[1].botline -- 1-based
  if end_row + 1 < topline or end_row + 1 > botline then
    return nil
  end
  -- 0-based row within the window content area.
  -- NOTE: does not account for virt_lines from cells above; rerender_all()
  -- corrects this with screenpos() after the redraw has settled.
  return (end_row + 1 - topline) + 1 + text_offset
end

--- Compute the precise 0-based row for a float using screenpos().
--- Only valid when called after Neovim has redrawn (e.g. from WinScrolled).
--- Returns nil when the cell is off-screen or screenpos returns 0.
---@param source_win integer
---@param end_row integer
---@param text_offset integer
---@return integer|nil
local function float_row_exact(source_win, end_row, text_offset)
  local info = vim.fn.getwininfo(source_win)
  if not info or not info[1] then
    return nil
  end
  local botline = info[1].botline
  if end_row + 1 > botline then
    return nil
  end
  local sp = vim.fn.screenpos(source_win, end_row + 1, 1)
  if sp.row == 0 then
    return nil
  end
  -- sp.row is a 1-based absolute terminal row.
  -- info[1].winrow is the 1-based terminal row of the window's top content line.
  return (sp.row - info[1].winrow) + 1 + text_offset
end

--- Open a scratch floating window for image rendering.
---@param source_win integer
---@param frow integer  0-based row relative to source_win
---@param cfg table
---@return integer float_win, integer float_buf
local function open_float(source_win, frow, cfg)
  local float_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(float_buf, "bufhidden", "wipe")
  local win_width = vim.api.nvim_win_get_width(source_win)
  local width = math.max(1, math.min(cfg.image.max_width, win_width - 4))
  local float_win = vim.api.nvim_open_win(float_buf, false, {
    relative = "win",
    win = source_win,
    row = frow,
    col = 2,
    width = width,
    height = cfg.image.max_height,
    style = "minimal",
    focusable = false,
    zindex = 10,
  })
  return float_win, float_buf
end

-- ── Rendering ─────────────────────────────────────────────────────────────────

--- Render one image chunk below a cell's text output.
---@param bufnr integer
---@param cell_state table
---@param chunk table   { type="image", mime, data }
---@param text_line_offset integer  text virt_lines (incl. dividers) above image
---@return boolean  true if image object was created
function M.render(bufnr, cell_state, chunk, text_line_offset)
  if not M.is_supported() then
    return false
  end

  local ok_api, image_api = pcall(require, "image")
  if not ok_api then
    return false
  end

  local cfg = require("ipynb.config").get()
  local cell_mod = require("ipynb.core.cell")
  local utils = require("ipynb.utils")

  text_line_offset = text_line_offset or 0

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

  local source_win = vim.fn.bufwinid(bufnr)
  if source_win == -1 then
    source_win = vim.api.nvim_get_current_win()
  end

  local key = cell_key(bufnr, cell_state)
  local img_id = "ipynb_" .. key:gsub(":", "_") .. "_" .. tostring(os.time())
  if not _registry[key] then
    _registry[key] = {}
  end

  local frow = float_row_approx(source_win, end_row, text_line_offset)

  if frow == nil then
    -- Off-screen: create image object without a float so rerender_all() can
    -- render it when the cell scrolls into view.
    local img
    ok_api, img = pcall(image_api.from_file, tmp, {
      id = img_id,
      buffer = bufnr,
      window = source_win,
      x = 2,
      y = end_row,
      width = cfg.image.max_width,
      height = cfg.image.max_height,
      with_virtual_padding = false,
    })
    if not ok_api then
      utils.debug("image.nvim from_file error (off-screen): " .. tostring(img))
      os.remove(tmp)
      return false
    end
    _registry[key][#_registry[key] + 1] = {
      img = img,
      tmp = tmp,
      float_win = nil,
      float_buf = nil,
      end_row = end_row,
      text_offset = text_line_offset,
      source_win = source_win,
    }
    return true
  end

  -- Visible: open a float and render the image inside it.
  local float_win, float_buf = open_float(source_win, frow, cfg)
  local win_width = vim.api.nvim_win_get_width(source_win)
  local float_width = math.max(1, math.min(cfg.image.max_width, win_width - 4))

  local img
  ok_api, img = pcall(image_api.from_file, tmp, {
    id = img_id,
    buffer = float_buf,
    window = float_win,
    x = 0,
    y = 0,
    width = float_width,
    height = cfg.image.max_height,
    with_virtual_padding = false,
  })
  if not ok_api then
    utils.debug("image.nvim from_file error: " .. tostring(img))
    pcall(vim.api.nvim_win_close, float_win, true)
    os.remove(tmp)
    return false
  end

  _registry[key][#_registry[key] + 1] = {
    img = img,
    tmp = tmp,
    float_win = float_win,
    float_buf = float_buf,
    end_row = end_row,
    text_offset = text_line_offset,
    source_win = source_win,
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
--- Called from the WinScrolled debounce. Uses screenpos() for precise
--- placement and applies the viewport guard to prevent tmux pane bleed.
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

      local frow = float_row_exact(source_win, entry.end_row, entry.text_offset)

      if frow == nil then
        -- Off-screen: close float to prevent tmux bleed.
        if entry.float_win and vim.api.nvim_win_is_valid(entry.float_win) then
          pcall(vim.api.nvim_win_close, entry.float_win, true)
          entry.float_win = nil
          entry.float_buf = nil
        end
        goto next_entry
      end

      local win_width = vim.api.nvim_win_get_width(source_win)
      local float_width = math.max(1, math.min(cfg.image.max_width, win_width - 4))

      if entry.float_win and vim.api.nvim_win_is_valid(entry.float_win) then
        -- Reposition existing float - no clear+redraw, just move the window.
        pcall(vim.api.nvim_win_set_config, entry.float_win, {
          relative = "win",
          win = source_win,
          row = frow,
          col = 2,
          width = float_width,
          height = cfg.image.max_height,
        })
        pcall(function()
          entry.img:render()
        end)
      else
        -- Cell was off-screen; now visible. Create float and render.
        if not entry.tmp or vim.fn.filereadable(entry.tmp) == 0 then
          goto next_entry
        end
        local float_win, float_buf = open_float(source_win, frow, cfg)
        local ok_from, img2 = pcall(image_api.from_file, entry.tmp, {
          id = "ipynb_retry_" .. key:gsub(":", "_") .. "_" .. tostring(os.time()),
          buffer = float_buf,
          window = float_win,
          x = 0,
          y = 0,
          width = float_width,
          height = cfg.image.max_height,
          with_virtual_padding = false,
        })
        if ok_from then
          pcall(function()
            entry.img:clear()
          end)
          entry.img = img2
          entry.float_win = float_win
          entry.float_buf = float_buf
          pcall(function()
            img2:render()
          end)
        else
          pcall(vim.api.nvim_win_close, float_win, true)
        end
      end

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
    pcall(function()
      entry.img:clear()
    end)
    if entry.float_win and vim.api.nvim_win_is_valid(entry.float_win) then
      pcall(vim.api.nvim_win_close, entry.float_win, true)
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
  return string.format("  [%s image — install image.nvim for rendering]", mime)
end

return M
