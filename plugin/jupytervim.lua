--- plugin/jupytervim.lua
--- Auto-loaded by Neovim on startup.
--- Calls setup() with an empty config so the plugin works out-of-the-box
--- without requiring the user to call require("jupytervim").setup() manually.
--- Users who want custom options should call setup() in their init.lua BEFORE
--- Neovim opens any .ipynb file (e.g., in their plugin spec's config/opts).

-- Guard: only run once and only in a full Neovim session (not headless).
if vim.g.loaded_jupytervim or vim.fn.has("nvim") == 0 then
  return
end
vim.g.loaded_jupytervim = true

-- Defer actual setup to after all plugins are loaded so that optional
-- dependencies (image.nvim, treesitter) are already available.
vim.api.nvim_create_autocmd("VimEnter", {
  once     = true,
  callback = function()
    -- Only auto-setup if the user has not already called setup() explicitly.
    local ok, jupytervim = pcall(require, "jupytervim")
    if ok and not jupytervim._setup_done then
      jupytervim.setup({})
    end
  end,
  desc = "jupytervim: lazy auto-setup on VimEnter",
})
