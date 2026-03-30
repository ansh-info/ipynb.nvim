--- ipynb.core.notebook_buf
--- Buffer lifecycle manager: ties together notebook.lua (I/O) and
--- cell.lua (rendering/extmarks) for a specific buffer.
---
--- Responsibilities:
---   - BufReadCmd handler: load .ipynb → render into buffer
---   - BufWriteCmd handler: sync buffer → save .ipynb
---   - Buffer option setup (filetype, conceallevel, etc.)
---   - Auto-save after cell execution (if configured)

local notebook = require("ipynb.core.notebook")
local cell = require("ipynb.core.cell")
local keymaps = require("ipynb.ui.keymaps")
local config = require("ipynb.config")
local utils = require("ipynb.utils")

local M = {}

-- Track which buffers ipynb has already initialised.
local managed = {}

-- ── Buffer setup ──────────────────────────────────────────────────────────────

--- Configure buffer-level options for a notebook buffer.
---@param bufnr integer
local function setup_buf_options(bufnr)
  -- Treat as a normal editable buffer.
  vim.api.nvim_buf_set_option(bufnr, "buftype", "")
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  vim.api.nvim_buf_set_option(bufnr, "readonly", false)
  vim.api.nvim_buf_set_option(bufnr, "swapfile", false)

  -- Python filetype for treesitter / LSP.
  vim.api.nvim_buf_set_option(bufnr, "filetype", "python")

  -- Disable formatters. The buffer holds raw cell source from multiple cells;
  -- running ruff/black/conform over it would corrupt multi-cell content and
  -- trigger spurious re-renders.
  vim.b[bufnr].conform_format_on_save = false
  vim.b[bufnr].conform_format_on_insert_leave = false
  vim.bo[bufnr].formatexpr = ""

  -- Conceal decorations look better without full conceallevel in insert mode.
  vim.api.nvim_win_set_option(0, "conceallevel", 0)
  vim.api.nvim_win_set_option(0, "signcolumn", "yes")
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

-- ── LSP attachment ───────────────────────────────────────────────────────────

--- Attach Python LSP clients to the notebook buffer.
---
--- The buffer is opened via BufReadCmd, which bypasses the normal file-open
--- path that triggers FileType autocmds with a valid buffer name.  Two
--- strategies together cover the common cases:
---
---   1. Re-fire "FileType python" via nvim_exec_autocmds.  This bypasses the
---      "filetype unchanged" guard so the event fires even though filetype is
---      already "python".  nvim-lspconfig, ruff-lsp, and Copilot all hook into
---      this event, so they will see the correct buffer name and attach.
---
---   2. Directly attach any Python LSP client that is already running (e.g.
---      started from a .py file that was open before this notebook).
---
---@param bufnr integer
local function attach_lsp(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- Strategy 1: re-fire FileType so lspconfig autostart logic runs.
  -- Use nvim_buf_call so the autocmd fires with bufnr as the current buffer.
  -- Without this, if another vim.schedule callback (e.g. kernel.start) ran
  -- first and changed the active buffer, lspconfig would see the wrong buffer
  -- in args.buf / <abuf> and attach to the wrong file.
  vim.api.nvim_buf_call(bufnr, function()
    vim.api.nvim_exec_autocmds("FileType", { pattern = "python" })
  end)

  -- Strategy 2: attach any already-running Python LSP client.
  local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients
  for _, client in ipairs(get_clients()) do
    if vim.lsp.buf_is_attached(bufnr, client.id) then
      goto continue
    end
    local fts = (client.config or {}).filetypes or {}
    for _, ft in ipairs(fts) do
      if ft == "python" then
        pcall(vim.lsp.buf_attach_client, bufnr, client.id)
        break
      end
    end
    ::continue::
  end
end

-- ── Sync: buffer → notebook model ────────────────────────────────────────────

--- Walk all cells and sync their current buffer content back into
--- notebook.cells[i].source before saving.
---@param bufnr integer
local function sync_all_cells(bufnr)
  local nb = cell.get_notebook(bufnr)
  local cells = cell.get_cells(bufnr)
  if not nb then
    return
  end

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
  local ok_cmp, completion = pcall(require, "ipynb.kernel.completion")
  if ok_cmp then
    completion.attach(bufnr)
  end

  -- Register inspector keymap.
  vim.keymap.set("n", "<leader>ji", function()
    require("ipynb.ui.inspector").open(bufnr)
  end, { buffer = bufnr, silent = true, desc = "Jupyter: variable inspector" })

  -- Auto-clean state on buffer wipe.
  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = bufnr,
    once = true,
    callback = function()
      cell.on_buf_delete(bufnr)
      -- Stop kernel bridge if one is running for this buffer.
      local ok, kernel = pcall(require, "ipynb.kernel")
      if ok then
        kernel.on_buf_delete(bufnr)
      end
      managed[bufnr] = nil
    end,
  })

  -- Re-anchor cell end marks after text edits and after undo/redo.
  -- Pressing 'o' on the last line of a cell inserts content below end_mark;
  -- on InsertLeave / TextChanged we recompute and reposition end_mark so the
  -- bottom border always wraps the actual cell content.
  -- sync_sources_from_buf keeps the notebook model current so that structural
  -- integrity checks and save use up-to-date sources.
  -- check_structural_integrity detects and recovers from structural undo
  -- (undoing add_cell / delete_cell leaving borders out of sync).
  vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
    buffer = bufnr,
    callback = function()
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      cell.sync_sources_from_buf(bufnr)
      cell.reanchor_end_marks(bufnr)
      cell.check_structural_integrity(bufnr)
    end,
  })

  -- Snap cursor back into the nearest cell if it escapes all cell regions.
  -- This prevents typing in the gap between cells from corrupting the buffer.
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = bufnr,
    callback = function()
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      local cs, _ = cell.cell_at_cursor(bufnr)
      if cs then
        return
      end
      -- Cursor is outside all cells - snap to nearest cell boundary.
      local cur_row = vim.api.nvim_win_get_cursor(0)[1] - 1
      cell.snap_cursor_to_nearest(bufnr, cur_row)
    end,
  })

  -- Re-render borders when the window is resized (border widths depend on
  -- the window width).
  vim.api.nvim_create_autocmd("VimResized", {
    buffer = bufnr,
    callback = function()
      local nb2 = cell.get_notebook(bufnr)
      if nb2 then
        cell.render(bufnr, nb2)
      end
    end,
  })

  -- Re-render images when the viewport scrolls so that:
  --   a) images follow the cell as it moves on screen (fixes flicker), and
  --   b) images whose initial render failed because the output was off-screen
  --      get a second chance once the user scrolls them into view.
  local ok_img = pcall(require, "ipynb.ui.image")
  if ok_img then
    local scroll_timer = nil

    vim.api.nvim_create_autocmd("WinScrolled", {
      buffer = bufnr,
      callback = function()
        if scroll_timer then
          scroll_timer:stop()
        else
          scroll_timer = vim.loop.new_timer()
        end
        scroll_timer:start(
          80,
          0,
          vim.schedule_wrap(function()
            if not vim.api.nvim_buf_is_valid(bufnr) then
              return
            end
            local ok2, image = pcall(require, "ipynb.ui.image")
            if ok2 then
              image.rerender_all(bufnr)
            end
          end)
        )
      end,
    })

    vim.api.nvim_create_autocmd("BufDelete", {
      buffer = bufnr,
      once = true,
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
      if ok then
        kernel.start(bufnr, nil)
      end
    end)
  end

  -- Attach LSP clients (pyright, pylsp, ruff-lsp, Copilot, etc.).
  -- Deferred so the buffer name and filetype are fully committed before
  -- lspconfig root_dir detection runs.
  vim.schedule(function()
    attach_lsp(bufnr)
  end)

  -- Mark buffer as not modified after initial load.
  vim.api.nvim_buf_set_option(bufnr, "modified", false)

  -- Move cursor to line 1. BufReadCmd can trigger a shada position restore
  -- via BufEnter autocmds after this handler returns, so defer until the
  -- next event loop tick to ensure we win.
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
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
