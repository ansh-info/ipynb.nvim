--- plugin/ipynb.lua
--- Auto-loaded by Neovim on startup.
---
--- With lazy.nvim (lazy = false) this file is sourced during startup and
--- lazy.nvim immediately calls setup(opts) afterwards — before Neovim opens
--- any file.  That is sufficient; BufReadCmd is registered inside setup()
--- via _register_autocmds() and fires correctly for CLI-opened .ipynb files.
---
--- For manual / packer installs the user must call
---   require("ipynb").setup(opts)
--- in their own init.lua (before any .ipynb buffer is opened).

if vim.g.loaded_ipynb or vim.fn.has("nvim") == 0 then
  return
end
vim.g.loaded_ipynb = true

-- Register :checkhealth ipynb provider.
vim.health = vim.health or {}
vim.api.nvim_create_user_command("IpynbHealth", function()
  vim.cmd("checkhealth ipynb")
end, { desc = "Run :checkhealth ipynb" })
