--- ipynb.completion
--- Kernel-backed completions for Jupyter notebook buffers.
---
--- Two integration points:
---
---   1. omnifunc  — set via `vim.bo.omnifunc` on the buffer; triggered by
---                  <C-x><C-o> in insert mode.  Uses vim.wait() to block
---                  briefly for kernel response (max 1.5 s).
---
---   2. nvim-cmp source — registers as a cmp source named "ipynb"
---                  when nvim-cmp is present.  Fully async via cmp callbacks.
---
--- Usage (automatic):
---   completion.attach(bufnr) is called from notebook_buf.open().
---
--- Usage (manual in config):
---   require("cmp").setup.buffer({ sources = {{ name = "ipynb" }} })

local M = {}

-- ── Shared completion logic ───────────────────────────────────────────────────

--- Find the column where the current completion token starts (0-based).
---@return integer
local function find_token_start()
  local col  = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line():sub(1, col)
  -- Walk backwards over identifier / attribute characters.
  local start = col
  while start > 0 do
    local ch = line:sub(start, start)
    if ch:match("[%w_%.%:]") then
      start = start - 1
    else
      break
    end
  end
  return start
end

--- Build the list of completion items from a kernel complete reply.
---@param msg table  complete message from kernel_bridge
---@return table[]   list of { word, menu } tables for omnifunc / cmp
local function build_items(msg)
  local items = {}
  for _, match in ipairs(msg.matches or {}) do
    items[#items + 1] = {
      word  = match,
      menu  = "[jupyter]",
      kind  = "Function",   -- cmp kind label (overridden per type in cmp source)
    }
  end
  return items
end

-- ── omnifunc ──────────────────────────────────────────────────────────────────

--- omnifunc-compatible function.
--- Called by Neovim with findstart=1 (find token start) then findstart=0
--- (return completions for `base`).
---@param findstart integer  1 or 0
---@param base string        the token being completed (findstart == 0)
---@return integer|table
function M.omnifunc(findstart, base)
  local bufnr = vim.api.nvim_get_current_buf()

  if findstart == 1 then
    return find_token_start()
  end

  -- Completion phase: ask the kernel.
  local ok, kernel = pcall(require, "ipynb.kernel")
  if not ok then return {} end
  if kernel.status(bufnr) ~= "idle" then return {} end

  local line       = vim.api.nvim_get_current_line()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)[2]
  local result     = nil

  kernel.complete(bufnr, line, cursor_pos, function(msg)
    result = msg
  end)

  -- Block until the kernel replies, up to 1.5 s (non-interactive safe).
  vim.wait(1500, function() return result ~= nil end, 10)

  if not result then return {} end
  return build_items(result)
end

-- ── nvim-cmp source ───────────────────────────────────────────────────────────

--- nvim-cmp source implementation.
--- Register with: require("cmp").register_source("ipynb", source)
local CmpSource = {}
CmpSource.__index = CmpSource

function CmpSource.new()
  return setmetatable({}, CmpSource)
end

function CmpSource:get_debug_name()
  return "ipynb"
end

--- cmp calls this to know whether the source applies at the current position.
function CmpSource:is_available()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok_nb, nb_buf = pcall(require, "ipynb.notebook_buf")
  if not ok_nb or not nb_buf.is_managed(bufnr) then return false end
  local ok_k, kernel = pcall(require, "ipynb.kernel")
  return ok_k and kernel.status(bufnr) == "idle"
end

--- cmp calls this to request completions asynchronously.
function CmpSource:complete(params, callback)
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, kernel = pcall(require, "ipynb.kernel")
  if not ok then callback({ items = {}, isIncomplete = false }) return end

  local line       = params.context.cursor_before_line
  local cursor_pos = #line

  kernel.complete(bufnr, line, cursor_pos, function(msg)
    local items = {}
    for _, match in ipairs(msg.matches or {}) do
      items[#items + 1] = {
        label            = match,
        kind             = require("cmp").lsp.CompletionItemKind.Function,
        detail           = "[jupyter kernel]",
        insertTextFormat = 1,  -- plain text
      }
    end
    callback({
      items        = items,
      isIncomplete = false,
    })
  end)
end

--- cmp trigger characters.
function CmpSource:get_trigger_characters()
  return { ".", "(" }
end

-- ── Buffer attachment ─────────────────────────────────────────────────────────

--- Attach completion to a notebook buffer.
--- Sets omnifunc and, if nvim-cmp is present, registers the source.
---@param bufnr integer
function M.attach(bufnr)
  -- Set omnifunc so <C-x><C-o> works without any extra plugins.
  vim.api.nvim_buf_set_option(bufnr, "omnifunc",
    "v:lua.require'ipynb.completion'.omnifunc")

  -- Register nvim-cmp source once if cmp is available.
  local ok, cmp = pcall(require, "cmp")
  if not ok then return end

  -- Only register once globally.
  if not M._cmp_registered then
    cmp.register_source("ipynb", CmpSource.new())
    M._cmp_registered = true
  end

  -- Add source to this buffer's cmp config.
  cmp.setup.buffer({
    sources = cmp.config.sources({
      { name = "ipynb", priority = 1000 },
    }, {
      { name = "buffer" },
    }),
  })
end

M._cmp_registered = false

return M
