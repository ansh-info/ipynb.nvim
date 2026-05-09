--- ipynb — main entry point
---
--- Usage (lazy.nvim):
---
---   {
---     "ansh-info/ipynb.nvim",
---     ft = "ipynb",
---     dependencies = {
---       "nvim-treesitter/nvim-treesitter",
---       "folke/snacks.nvim",        -- optional, for image rendering
---     },
---     opts = {
---       -- override any defaults from config.lua
---       keymaps = { run_cell = "<leader>x" },
---     },
---   }
---
--- Or manually:
---
---   require("ipynb").setup({})

local M = {}

local _setup_done = false

--- Plugin setup.  Must be called before opening any .ipynb file.
---@param opts table|nil  Overrides for the default config (see config.lua).
function M.setup(opts)
  if _setup_done then
    return
  end
  _setup_done = true

  -- Seed the RNG so gen_cell_id() produces unique IDs across sessions.
  math.randomseed(os.time() + (vim.uv or vim.loop).now())

  -- Merge user options into defaults.
  require("ipynb.config").setup(opts)

  -- Register :Jupyter* commands.
  require("ipynb.ui.commands").setup()

  -- Register the BufReadCmd autocmd that intercepts .ipynb file opens.
  M._register_autocmds()
end

--- Register the autocmds that make .ipynb files load through ipynb.
function M._register_autocmds()
  local group = vim.api.nvim_create_augroup("Ipynb", { clear = true })

  -- BufReadCmd fires instead of the normal file-read when Neovim opens the
  -- matching file, giving us full control over buffer population.
  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = group,
    pattern = "*.ipynb",
    callback = function(ev)
      local path = vim.fn.expand(ev.match)
      local bufnr = ev.buf
      require("ipynb.core.notebook_buf").open(path, bufnr)
    end,
    desc = "ipynb: open .ipynb notebook",
  })

  -- BufWriteCmd fires instead of the normal write, so :w saves through our
  -- serialiser rather than writing raw buffer content.
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    group = group,
    pattern = "*.ipynb",
    callback = function(ev)
      local bufnr = ev.buf
      if require("ipynb.core.notebook_buf").is_managed(bufnr) then
        require("ipynb.core.notebook_buf").save(bufnr)
      else
        -- Fall through to normal write for unmanaged buffers.
        vim.cmd("noautocmd write")
      end
    end,
    desc = "ipynb: save .ipynb notebook",
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      local ok, kernel = pcall(require, "ipynb.kernel")
      if ok then
        kernel.stop_all()
      end
    end,
    desc = "ipynb: shut down all kernels before Neovim exits",
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      require("ipynb.core.cell").define_highlights()
      require("ipynb.ui.ansi").reset_highlights()
      local ok_md, md = pcall(require, "ipynb.ui.markdown")
      if ok_md then
        md.define_highlights()
      end
      local ok_ins, ins = pcall(require, "ipynb.ui.inspector")
      if ok_ins then
        ins.define_highlights()
      end
    end,
    desc = "ipynb: re-register highlights after colorscheme change",
  })
end

-- ── Convenience public API ────────────────────────────────────────────────────

--- Programmatically open a notebook path in the current window.
---@param path string
function M.open(path)
  local bufnr = vim.api.nvim_get_current_buf()
  require("ipynb.core.notebook_buf").open(vim.fn.expand(path), bufnr)
end

--- Save the notebook in the current buffer.
function M.save()
  require("ipynb.core.notebook_buf").save(vim.api.nvim_get_current_buf())
end

--- Return the internal notebook data for the current buffer (useful for
--- scripting and extension development).
---@return table|nil
function M.get_notebook()
  return require("ipynb.core.cell").get_notebook(vim.api.nvim_get_current_buf())
end

-- ── Statusline component ─────────────────────────────────────────────────────

local _status_icons = {
  idle = { icon = "⬤", hl = "DiagnosticOk" },
  busy = { icon = "⬤", hl = "DiagnosticWarn" },
  starting = { icon = "⬤", hl = "DiagnosticInfo" },
  stopped = { icon = "⬤", hl = "DiagnosticError" },
}

--- Return a formatted string showing the kernel name and status for the
--- current buffer.  Designed for embedding in lualine, heirline, or any
--- statusline plugin.
---
--- Returns an empty string when the current buffer is not a managed notebook,
--- so the component disappears outside of .ipynb files.
---
--- Example output: "⬤ python3 [idle]"
---
---@return string
function M.statusline()
  local bufnr = vim.api.nvim_get_current_buf()
  if not require("ipynb.core.notebook_buf").is_managed(bufnr) then
    return ""
  end

  local ok, kernel = pcall(require, "ipynb.kernel")
  if not ok then
    return ""
  end

  local status = kernel.status(bufnr)
  local name = kernel.kernel_name(bufnr)
  local entry = _status_icons[status] or _status_icons.stopped

  if name == "" then
    return entry.icon .. " (no kernel)"
  end
  return entry.icon .. " " .. name .. " [" .. status .. "]"
end

--- Return the highlight group name for the current kernel status.
--- Useful for statusline plugins that support per-component coloring.
---
---@return string  highlight group name (e.g. "DiagnosticOk")
function M.statusline_hl()
  local bufnr = vim.api.nvim_get_current_buf()
  if not require("ipynb.core.notebook_buf").is_managed(bufnr) then
    return "StatusLine"
  end

  local ok, kernel = pcall(require, "ipynb.kernel")
  if not ok then
    return "StatusLine"
  end

  local status = kernel.status(bufnr)
  local entry = _status_icons[status] or _status_icons.stopped
  return entry.hl
end

return M
