--- ipynb.ui.ansi
--- Parse ANSI SGR escape sequences into {text, hl_group} pairs for virt_lines.
---
--- Supports:
---   - Standard 16 foreground/background colors (30-37, 40-47, 90-97, 100-107)
---   - Bold (1), italic (3), underline (4) and their resets
---   - 256-color mode (38;5;N / 48;5;N)
---   - Truecolor mode (38;2;R;G;B / 48;2;R;G;B)
---   - Reset (0)
---
--- Public API:
---   ansi.parse_line(line, default_hl) -> {{text, hl}, ...}
---   ansi.has_ansi(text) -> boolean

local M = {}

-- ── 16-color palette ─────────────────────────────────────────────────────────
-- Chosen for readability on dark backgrounds.

local PALETTE_16 = {
  [0] = "#4c4c4c",
  [1] = "#ff6b6b",
  [2] = "#69db7c",
  [3] = "#ffd43b",
  [4] = "#74c0fc",
  [5] = "#da77f2",
  [6] = "#66d9e8",
  [7] = "#ced4da",
  [8] = "#868e96",
  [9] = "#ff8787",
  [10] = "#8ce99a",
  [11] = "#ffe066",
  [12] = "#a5d8ff",
  [13] = "#e599f7",
  [14] = "#99e9f2",
  [15] = "#f8f9fa",
}

-- ── 256-color palette (lazy) ─────────────────────────────────────────────────

local _palette_256

--- Return the hex color for a 256-color index.
---@param n integer  0-255
---@return string|nil  hex color like "#rrggbb"
local function palette_256(n)
  if n < 0 or n > 255 then
    return nil
  end
  if not _palette_256 then
    _palette_256 = {}
    for i = 0, 15 do
      _palette_256[i] = PALETTE_16[i]
    end
    -- 6x6x6 color cube (16-231).
    for i = 16, 231 do
      local idx = i - 16
      local b = idx % 6
      local g = math.floor(idx / 6) % 6
      local r = math.floor(idx / 36)
      _palette_256[i] = string.format(
        "#%02x%02x%02x",
        r > 0 and (r * 40 + 55) or 0,
        g > 0 and (g * 40 + 55) or 0,
        b > 0 and (b * 40 + 55) or 0
      )
    end
    -- Grayscale ramp (232-255).
    for i = 232, 255 do
      local v = (i - 232) * 10 + 8
      _palette_256[i] = string.format("#%02x%02x%02x", v, v, v)
    end
  end
  return _palette_256[n]
end

-- ── Dynamic highlight group cache ────────────────────────────────────────────

local _hl_cache = {}
local _hl_counter = 0

--- Return (creating if needed) a highlight group for the given ANSI style.
---@param fg string|nil
---@param bg string|nil
---@param bold boolean
---@param italic boolean
---@param underline boolean
---@param default_hl string
---@return string  highlight group name
local function get_hl(fg, bg, bold, italic, underline, default_hl)
  if not fg and not bg and not bold and not italic and not underline then
    return default_hl
  end

  local key = (fg or "")
    .. "|"
    .. (bg or "")
    .. "|"
    .. (bold and "b" or "")
    .. (italic and "i" or "")
    .. (underline and "u" or "")

  local cached = _hl_cache[key]
  if cached then
    return cached
  end

  _hl_counter = _hl_counter + 1
  local name = "IpynbAnsi" .. _hl_counter

  local opts = {}
  if fg then
    opts.fg = fg
  end
  if bg then
    opts.bg = bg
  end
  if bold then
    opts.bold = true
  end
  if italic then
    opts.italic = true
  end
  if underline then
    opts.underline = true
  end

  vim.api.nvim_set_hl(0, name, opts)
  _hl_cache[key] = name
  return name
end

-- ── SGR parameter interpreter ────────────────────────────────────────────────

--- Apply one SGR parameter sequence to the current style state.
--- Returns updated (fg, bg, bold, italic, underline).
---@param params string  semicolon-separated numbers (e.g. "1;31")
---@return string|nil fg
---@return string|nil bg
---@return boolean bold
---@return boolean italic
---@return boolean underline
local function apply_sgr(params, fg, bg, bold, italic, underline)
  local codes = {}
  for code in (params .. ";"):gmatch("(%d+);") do
    codes[#codes + 1] = tonumber(code)
  end
  -- Bare ESC[m is a reset.
  if #codes == 0 then
    return nil, nil, false, false, false
  end

  local i = 1
  while i <= #codes do
    local c = codes[i]
    if c == 0 then
      fg, bg, bold, italic, underline = nil, nil, false, false, false
    elseif c == 1 then
      bold = true
    elseif c == 3 then
      italic = true
    elseif c == 4 then
      underline = true
    elseif c == 22 then
      bold = false
    elseif c == 23 then
      italic = false
    elseif c == 24 then
      underline = false
    elseif c >= 30 and c <= 37 then
      fg = PALETTE_16[c - 30]
    elseif c == 39 then
      fg = nil
    elseif c >= 40 and c <= 47 then
      bg = PALETTE_16[c - 40]
    elseif c == 49 then
      bg = nil
    elseif c >= 90 and c <= 97 then
      fg = PALETTE_16[c - 90 + 8]
    elseif c >= 100 and c <= 107 then
      bg = PALETTE_16[c - 100 + 8]
    elseif c == 38 or c == 48 then
      -- Extended color: 38;5;N (256-color) or 38;2;R;G;B (truecolor).
      local is_fg = (c == 38)
      if codes[i + 1] == 5 and codes[i + 2] then
        local color = palette_256(codes[i + 2])
        if is_fg then
          fg = color
        else
          bg = color
        end
        i = i + 2
      elseif codes[i + 1] == 2 and codes[i + 4] then
        local color = string.format("#%02x%02x%02x", codes[i + 2], codes[i + 3], codes[i + 4])
        if is_fg then
          fg = color
        else
          bg = color
        end
        i = i + 4
      end
    end
    i = i + 1
  end

  return fg, bg, bold, italic, underline
end

-- ── Public API ───────────────────────────────────────────────────────────────

--- Parse a single line containing ANSI SGR escape sequences into a list of
--- {text, hl_group} pairs suitable for virt_line chunks.
---
--- Non-SGR escape sequences (cursor movement, etc.) are silently skipped.
---
---@param line string  raw line potentially containing ANSI escapes
---@param default_hl string  highlight group for unstyled text
---@return table[]  list of {string, string} pairs
function M.parse_line(line, default_hl)
  local chunks = {}
  local pos = 1
  local fg, bg = nil, nil
  local bold, italic, underline = false, false, false

  while pos <= #line do
    -- Find the next ESC[
    local esc_start = line:find("\27%[", pos)

    if not esc_start then
      -- No more escapes - emit the rest.
      local text = line:sub(pos)
      if text ~= "" then
        chunks[#chunks + 1] = { text, get_hl(fg, bg, bold, italic, underline, default_hl) }
      end
      break
    end

    -- Emit text before the escape.
    if esc_start > pos then
      local text = line:sub(pos, esc_start - 1)
      if text ~= "" then
        chunks[#chunks + 1] = { text, get_hl(fg, bg, bold, italic, underline, default_hl) }
      end
    end

    -- Match the full CSI sequence: ESC [ params final_byte
    local params, final_byte = line:match("^\27%[([0-9;]*)([A-Za-z])", esc_start)
    if params and final_byte then
      if final_byte == "m" then
        -- SGR: update style state.
        fg, bg, bold, italic, underline = apply_sgr(params, fg, bg, bold, italic, underline)
      end
      -- Non-SGR CSI sequences (cursor movement, etc.) are silently skipped.
      pos = esc_start + 2 + #params + 1 -- ESC[ + params + final_byte
    else
      -- Malformed escape: emit the ESC as literal text and move on.
      chunks[#chunks + 1] = { "\27", get_hl(fg, bg, bold, italic, underline, default_hl) }
      pos = esc_start + 1
    end
  end

  if #chunks == 0 then
    chunks[#chunks + 1] = { "", default_hl }
  end

  return chunks
end

--- Check whether a string contains ANSI escape sequences.
---@param text string
---@return boolean
function M.has_ansi(text)
  return text:find("\27%[") ~= nil
end

function M.reset_highlights()
  _hl_cache = {}
  _hl_counter = 0
end

return M
