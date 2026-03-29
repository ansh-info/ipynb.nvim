--- ipynb — main entry point
---
--- Usage (lazy.nvim):
---
---   {
---     "ansh-info/ipynb.nvim",
---     ft = "ipynb",
---     dependencies = {
---       "nvim-treesitter/nvim-treesitter",
---       "3rd/image.nvim",          -- optional, for image rendering
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

  -- WinResized: re-render borders when the window width changes (border
  -- decorations are width-aware).
  vim.api.nvim_create_autocmd("WinResized", {
    group = group,
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      if require("ipynb.core.notebook_buf").is_managed(bufnr) then
        local nb = require("ipynb.core.cell").get_notebook(bufnr)
        if nb then
          require("ipynb.core.cell").render(bufnr, nb)
        end
      end
    end,
    desc = "ipynb: re-render on window resize",
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

return M
