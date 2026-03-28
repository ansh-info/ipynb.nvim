--- plugin/jupytervim.lua
--- Auto-loaded by Neovim on startup.
---
--- With lazy.nvim (lazy = false) this file is sourced during startup and
--- lazy.nvim immediately calls setup(opts) afterwards — before Neovim opens
--- any file.  That is sufficient; BufReadCmd is registered inside setup()
--- via _register_autocmds() and fires correctly for CLI-opened .ipynb files.
---
--- For manual / packer installs the user must call
---   require("jupytervim").setup(opts)
--- in their own init.lua (before any .ipynb buffer is opened).

if vim.g.loaded_jupytervim or vim.fn.has("nvim") == 0 then
  return
end
vim.g.loaded_jupytervim = true
