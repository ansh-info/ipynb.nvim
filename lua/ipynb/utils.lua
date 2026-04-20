--- ipynb.utils
--- Shared helper utilities used across the plugin.

local M = {}

--- Log a message prefixed with the plugin name.
---@param msg string
---@param level integer  vim.log.levels.*
function M.log(msg, level)
  vim.notify("[ipynb] " .. msg, level or vim.log.levels.INFO)
end

function M.warn(msg)
  M.log(msg, vim.log.levels.WARN)
end
function M.err(msg)
  M.log(msg, vim.log.levels.ERROR)
end
function M.info(msg)
  M.log(msg, vim.log.levels.INFO)
end
function M.debug(msg)
  M.log(msg, vim.log.levels.DEBUG)
end

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

return M
