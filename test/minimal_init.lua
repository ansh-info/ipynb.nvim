-- Minimal Neovim init used by vusted when running the test suite.
--
-- vusted adds the repo root to runtimepath automatically so that
-- require("ipynb.*") resolves against lua/ipynb/*.lua.
--
-- Add any lightweight stubs here that every spec needs.
-- Do NOT load real plugin dependencies (image.nvim, nvim-cmp, etc.) -
-- tests that need them should stub the require() call themselves.

-- Silence startup messages so test output is clean.
vim.opt.shortmess:append("I")

-- Provide a minimal vim.notify stub so modules that call utils.info/warn/err
-- during loading do not crash in headless mode.
if not vim.notify then
  vim.notify = function() end
end
