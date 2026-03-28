--- ipynb.notebook_buf
--- Buffer lifecycle manager: ties together notebook.lua (I/O) and
--- cell.lua (rendering/extmarks) for a specific buffer.
---
--- Responsibilities:
---   - BufReadCmd handler: load .ipynb → render into buffer
---   - BufWriteCmd handler: sync buffer → save .ipynb
---   - Buffer option setup (filetype, conceallevel, etc.)
---   - Auto-save after cell execution (if configured)

local notebook = require("ipynb.notebook")
local cell     = require("ipynb.cell")
local keymaps  = require("ipynb.keymaps")
local config   = require("ipynb.config")
local utils    = require("ipynb.utils")

local M = {}

-- Track which buffers ipynb has already initialised.
local managed = {}

-- ── Buffer setup ──────────────────────────────────────────────────────────────

--- Configure buffer-level options for a notebook buffer.
---@param bufnr integer
local function setup_buf_options(bufnr)
  -- Treat as a normal editable buffer.
  vim.api.nvim_buf_set_option(bufnr, "buftype",    "")
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_option(bufnr, "readonly",   false)
  vim.api.nvim_buf_set_option(bufnr, "swapfile",   false)

  -- Python filetype for treesitter / LSP.
  vim.api.nvim_buf_set_option(bufnr, "filetype", "python")

  -- Disable formatters. The buffer holds raw cell source from multiple cells;
  -- running ruff/black/conform over it would corrupt multi-cell content and
  -- trigger spurious re-renders.
  vim.b[bufnr].conform_format_on_save         = false
  vim.b[bufnr].conform_format_on_insert_leave = false
  vim.bo[bufnr].formatexpr                    = ""

  -- Conceal decorations look better without full conceallevel in insert mode.
  vim.api.nvim_win_set_option(0, "conceallevel", 0)
  vim.api.nvim_win_set_option(0, "signcolumn",   "yes")
end

--- Set a human-readable buffer name (shows in tabline / statusline).
---@param bufnr integer
---@param path string
local function set_buf_name(bufnr, path)
  local short = vim.fn.fnamemodify(path, ":t")
  vim.api.nvim_buf_set_name(bufnr, path)
  -- The statusline can read b:ipynb_name for a custom display.
  vim.api.nvim_buf_set_var(bufnr, "ipynb_name", short)
  vim.api.nvim_buf_set_var(bufnr, "ipynb_path", path)
end

-- ── Sync: buffer → notebook model ────────────────────────────────────────────

--- Walk all cells and sync their current buffer content back into
--- notebook.cells[i].source before saving.
---@param bufnr integer
local function sync_all_cells(bufnr)
  local nb     = cell.get_notebook(bufnr)
  local cells  = cell.get_cells(bufnr)
  if not nb then return end

  for _, cs in ipairs(cells) do
    local source = cell.get_cell_source(bufnr, cs)
    nb.cells[cs.index].source = source
  end
end

-- ── Public API ────────────────────────────────────────────────────────────────

--- Open a .ipynb file: parse it and render its cells into `bufnr`.
--- Called from the BufReadCmd autocmd.
---@param path string  Absolute path of the notebook file.
---@param bufnr integer
function M.open(path, bufnr)
  if managed[bufnr] then
    -- Already open; re-render from disk.
    local nb, err = notebook.load(path)
    if not nb then
      utils.err("Failed to reload notebook: " .. (err or path))
      return
    end
    cell.render(bufnr, nb)
    return
  end

  local nb, err = notebook.load(path)
  if not nb then
    utils.err("Failed to open notebook: " .. (err or path))
    -- Leave the buffer with the raw JSON so the user can inspect it.
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    return
  end

  -- Mark as managed before calling render so recursive triggers don't loop.
  managed[bufnr] = true

  setup_buf_options(bufnr)
  set_buf_name(bufnr, path)

  cell.render(bufnr, nb)
  keymaps.attach(bufnr)

  -- Attach kernel completions (omnifunc + optional nvim-cmp source).
  local ok_cmp, completion = pcall(require, "ipynb.completion")
  if ok_cmp then completion.attach(bufnr) end

  -- Register inspector keymap.
  vim.keymap.set("n", "<leader>ji", function()
    require("ipynb.inspector").open(bufnr)
  end, { buffer = bufnr, silent = true, desc = "Jupyter: variable inspector" })

  -- Auto-clean state on buffer wipe.
  vim.api.nvim_create_autocmd("BufDelete", {
    buffer  = bufnr,
    once    = true,
    callback = function()
      cell.on_buf_delete(bufnr)
      -- Stop kernel bridge if one is running for this buffer.
      local ok, kernel = pcall(require, "ipynb.kernel")
      if ok then kernel.on_buf_delete(bufnr) end
      managed[bufnr] = nil
    end,
  })

  -- Re-render borders when the window is resized (border widths depend on
  -- the window width).
  vim.api.nvim_create_autocmd("VimResized", {
    buffer   = bufnr,
    callback = function()
      local nb2 = cell.get_notebook(bufnr)
      if nb2 then cell.render(bufnr, nb2) end
    end,
  })

  -- Re-render images when the viewport scrolls so that:
  --   a) images follow the cell as it moves on screen (fixes flicker), and
  --   b) images whose initial render failed because the output was off-screen
  --      get a second chance once the user scrolls them into view.
  local ok_img = pcall(require, "ipynb.image")
  if ok_img then
    local scroll_timer = nil

    vim.api.nvim_create_autocmd("WinScrolled", {
      buffer   = bufnr,
      callback = function()
        if scroll_timer then
          scroll_timer:stop()
        else
          scroll_timer = vim.loop.new_timer()
        end
        scroll_timer:start(80, 0, vim.schedule_wrap(function()
          if not vim.api.nvim_buf_is_valid(bufnr) then return end
          local ok2, image = pcall(require, "ipynb.image")
          if ok2 then image.rerender_all(bufnr) end
        end))
      end,
    })

    vim.api.nvim_create_autocmd("BufDelete", {
      buffer   = bufnr,
      once     = true,
      callback = function()
        if scroll_timer then
          scroll_timer:stop()
          scroll_timer:close()
          scroll_timer = nil
        end
      end,
    })
  end

  -- Auto-start the kernel immediately so it is ready by the time the user
  -- first presses <leader>r.  Use vim.schedule so the buffer is fully
  -- rendered before the kernel subprocess is spawned.
  if config.get().kernel.auto_start then
    vim.schedule(function()
      local ok, kernel = pcall(require, "ipynb.kernel")
      if ok then kernel.start(bufnr, nil) end
    end)
  end

  -- Mark buffer as not modified after initial load.
  vim.api.nvim_buf_set_option(bufnr, "modified", false)

  -- Move cursor to line 1. BufReadCmd can trigger a shada position restore
  -- via BufEnter autocmds after this handler returns, so defer until the
  -- next event loop tick to ensure we win.
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then return end
    local win = vim.fn.bufwinid(bufnr)
    if win ~= -1 then
      vim.api.nvim_win_set_cursor(win, { 1, 0 })
    end
  end)
end

--- Save the current buffer as a .ipynb file.
--- Syncs all cell sources from the buffer, then serialises to JSON.
---@param bufnr integer
function M.save(bufnr)
  if not managed[bufnr] then
    utils.warn("Buffer is not a managed Jupyter notebook.")
    return
  end

  sync_all_cells(bufnr)

  local nb = cell.get_notebook(bufnr)
  if not nb then
    utils.err("No notebook data found for buffer.")
    return
  end

  local ok, err = notebook.save(nb)
  if ok then
    vim.api.nvim_buf_set_option(bufnr, "modified", false)
    utils.info("Notebook saved: " .. vim.fn.fnamemodify(nb.path, ":t"))
  else
    utils.err("Save failed: " .. (err or "unknown error"))
  end
end

--- Return true if the buffer is managed by ipynb.
---@param bufnr integer
---@return boolean
function M.is_managed(bufnr)
  return managed[bufnr] == true
end

return M
