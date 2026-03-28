--- jupytervim.utils
--- Shared helper utilities used across the plugin.

local M = {}

--- Log a message prefixed with the plugin name.
---@param msg string
---@param level integer  vim.log.levels.*
function M.log(msg, level)
  vim.notify("[jupytervim] " .. msg, level or vim.log.levels.INFO)
end

function M.warn(msg)  M.log(msg, vim.log.levels.WARN)  end
function M.err(msg)   M.log(msg, vim.log.levels.ERROR) end
function M.info(msg)  M.log(msg, vim.log.levels.INFO)  end
function M.debug(msg) M.log(msg, vim.log.levels.DEBUG) end

--- Read a file on disk and return its contents as a string.
--- Returns nil and an error message on failure.
---@param path string
---@return string|nil, string|nil
function M.read_file(path)
  local f, err = io.open(path, "r")
  if not f then
    return nil, err
  end
  local content = f:read("*a")
  f:close()
  return content, nil
end

--- Write content to a file on disk.
---@param path string
---@param content string
---@return boolean, string|nil
function M.write_file(path, content)
  local f, err = io.open(path, "w")
  if not f then
    return false, err
  end
  f:write(content)
  f:close()
  return true, nil
end

--- Encode bytes to base64 (used for image data).
--- Delegates to Python when large; for small strings uses a pure-Lua fallback.
---@param data string
---@return string
function M.b64_encode(data)
  -- Use system base64 command for reliability.
  local tmp = os.tmpname()
  local f = io.open(tmp, "wb")
  if not f then return "" end
  f:write(data)
  f:close()
  local result = vim.fn.system("base64 -w0 " .. tmp)
  os.remove(tmp)
  return vim.trim(result)
end

--- Decode a base64 string to raw bytes.
---@param b64 string
---@return string
function M.b64_decode(b64)
  local tmp_in  = os.tmpname()
  local tmp_out = os.tmpname()
  M.write_file(tmp_in, b64)
  vim.fn.system("base64 -d " .. tmp_in .. " > " .. tmp_out)
  os.remove(tmp_in)
  local raw = M.read_file(tmp_out) or ""
  os.remove(tmp_out)
  return raw
end

--- Return a temporary file path with the given extension.
---@param ext string  e.g. "png"
---@return string
function M.tmpfile(ext)
  return os.tmpname() .. "." .. ext
end

--- Split a string by a delimiter and return a list of parts.
---@param s string
---@param sep string  single-character delimiter
---@return string[]
function M.split(s, sep)
  local parts = {}
  for part in s:gmatch("([^" .. sep .. "]+)") do
    parts[#parts + 1] = part
  end
  return parts
end

--- Pad a string on the right to the given width.
---@param s string
---@param width integer
---@return string
function M.rpad(s, width)
  local len = vim.fn.strdisplaywidth(s)
  if len >= width then return s end
  return s .. string.rep(" ", width - len)
end

--- Return the 0-based line number of the cursor in the given buffer.
---@param bufnr integer
---@return integer
function M.cursor_line(bufnr)
  if bufnr == 0 or bufnr == vim.api.nvim_get_current_buf() then
    return vim.api.nvim_win_get_cursor(0)[1] - 1
  end
  -- For non-current buffers we can't get cursor; return 0.
  return 0
end

--- Check whether a given plugin is available (installed and loadable).
---@param name string  plugin module name, e.g. "image"
---@return boolean
function M.has_plugin(name)
  local ok = pcall(require, name)
  return ok
end

--- Return a unique string ID for the current microsecond.
---@return string
function M.uid()
  return tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999))
end

return M
