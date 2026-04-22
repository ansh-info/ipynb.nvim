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

-- Reverse map: normalised path → bufnr.  Used to detect when the same
-- notebook file is opened in a second buffer, which would cause silent
-- save conflicts (both buffers write to the same .ipynb).
local managed_paths = {}

-- ── Buffer setup ──────────────────────────────────────────────────────────────

--- Apply window-level options to whatever window is displaying this buffer.
---@param winid integer
local function setup_win_options(winid)
  vim.wo[winid].conceallevel = 2
  vim.wo[winid].signcolumn = "yes"
end

--- Configure buffer-level options for a notebook buffer.
---@param bufnr integer
local function setup_buf_options(bufnr)
  -- Treat as a normal editable buffer.
  vim.bo[bufnr].buftype = ""
  vim.bo[bufnr].modifiable = true
  vim.bo[bufnr].readonly = false
  vim.bo[bufnr].swapfile = false

  -- Disable formatters. The buffer holds raw cell source from multiple cells;
  -- running ruff/black/conform over it would corrupt multi-cell content and
  -- trigger spurious re-renders.
  vim.b[bufnr].conform_format_on_save = false
  vim.b[bufnr].conform_format_on_insert_leave = false
  vim.bo[bufnr].formatexpr = ""

  -- conceallevel=2 lets markdown.lua conceal heading markers, blockquote
  -- prefixes, and link delimiters.  Target the actual notebook window, not
  -- window 0 which may be a different split.
  local win = vim.fn.bufwinid(bufnr)
  if win ~= -1 then
    setup_win_options(win)
  end
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
  -- The buffer filetype is set by cell.render() from notebook metadata before
  -- this function is called.  pattern= must match the actual filetype so the
  -- correct LSP server attaches (e.g. r_language_server for R notebooks).
  local buf_ft = vim.bo[bufnr].filetype
  vim.api.nvim_exec_autocmds("FileType", { pattern = buf_ft, buffer = bufnr })

  -- Strategy 2: attach any already-running LSP client that serves this filetype.
  local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients
  for _, client in ipairs(get_clients()) do
    if vim.lsp.buf_is_attached(bufnr, client.id) then
      goto continue
    end
    local fts = (client.config or {}).filetypes or {}
    for _, ft in ipairs(fts) do
      if ft == buf_ft then
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
  local norm_path = vim.fn.fnamemodify(path, ":p")

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

  -- Guard: if another buffer already manages this file, switch to it
  -- instead of creating a duplicate that would cause silent save conflicts.
  local existing = managed_paths[norm_path]
  if existing and existing ~= bufnr and vim.api.nvim_buf_is_valid(existing) then
    utils.warn("Notebook already open in buffer " .. existing .. ". Switching to it.")
    -- Wipe the empty duplicate buffer and jump to the existing one.
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
      if vim.api.nvim_buf_is_valid(existing) then
        vim.api.nvim_set_current_buf(existing)
      end
    end)
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
  managed_paths[norm_path] = bufnr

  setup_buf_options(bufnr)
  set_buf_name(bufnr, path)

  local ft = require("ipynb.core.notebook").notebook_language(nb)
  vim.bo[bufnr].filetype = ft

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
      -- Clean up output state, image placements, and temp files BEFORE
      -- cell.on_buf_delete wipes buf_state (which holds the cell list).
      local cells = cell.get_cells(bufnr)
      if cells and #cells > 0 then
        local ok_out, output_mod = pcall(require, "ipynb.kernel.output")
        if ok_out then
          output_mod.clear_all(bufnr, cells)
        end
      end
      cell.on_buf_delete(bufnr)
      -- Stop kernel bridge if one is running for this buffer.
      local ok, kernel = pcall(require, "ipynb.kernel")
      if ok then
        kernel.on_buf_delete(bufnr)
      end
      -- Remove from both tracking tables so the path can be reopened.
      managed_paths[norm_path] = nil
      managed[bufnr] = nil
    end,
  })

  -- Apply window options when the buffer first appears in a window (handles
  -- background-loaded buffers from session restore, :badd, etc.).
  vim.api.nvim_create_autocmd("BufWinEnter", {
    buffer = bufnr,
    callback = function()
      local win = vim.fn.bufwinid(bufnr)
      if win ~= -1 then
        setup_win_options(win)
      end
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
      -- Identify the active cell once and pass the index to both functions so
      -- each only processes the edited cell and its immediate neighbours.
      -- This reduces per-keystroke extmark reads from O(n) to O(1).
      local _, active_idx = cell.cell_at_cursor(bufnr)
      cell.sync_sources_from_buf(bufnr, active_idx)
      cell.reanchor_end_marks(bufnr, active_idx)
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

  -- Smart undo/redo: route to notebook-level undo when the native undo tree
  -- is at the baseline (no text edits since last structural render), otherwise
  -- fall through to native undo.  This gives correct behavior for both
  -- in-cell text edits (native u) and structural ops (notebook undo).
  vim.keymap.set("n", "u", function()
    local seq = vim.fn.undotree().seq_cur or 0
    local base = cell.get_undo_base_seq(bufnr)
    if seq <= base and cell.has_notebook_undo(bufnr) then
      cell.notebook_undo(bufnr)
    else
      vim.cmd("silent! undo")
      cell.reanchor_end_marks(bufnr, nil)
      cell.check_structural_integrity(bufnr)
    end
  end, { buffer = bufnr, silent = true, desc = "Jupyter: smart undo" })

  vim.keymap.set("n", "<C-r>", function()
    local seq = vim.fn.undotree().seq_cur or 0
    local base = cell.get_undo_base_seq(bufnr)
    if seq == base and cell.has_notebook_redo(bufnr) then
      cell.notebook_redo(bufnr)
    else
      vim.cmd("silent! redo")
      cell.reanchor_end_marks(bufnr, nil)
      cell.check_structural_integrity(bufnr)
    end
  end, { buffer = bufnr, silent = true, desc = "Jupyter: smart redo" })

  -- Re-render borders when the window width changes.  Border text is built
  -- once at render time using the current window width; they need to be
  -- redrawn whenever that width changes.
  --
  -- VimResized fires on terminal resize but NOT when the user opens or closes
  -- a vertical split.  WinEnter fires on every window switch, so we track the
  -- last rendered width and skip the re-render when width is unchanged.
  local _last_win_width = vim.api.nvim_win_get_width(0)

  local function rerender_if_width_changed()
    local nb2 = cell.get_notebook(bufnr)
    if not nb2 then
      return
    end
    local w = vim.api.nvim_win_get_width(0)
    if w ~= _last_win_width then
      _last_win_width = w
      cell.sync_sources_from_buf(bufnr, nil)
      cell.render(bufnr, nb2)
    end
  end

  vim.api.nvim_create_autocmd("VimResized", {
    buffer = bufnr,
    callback = function()
      local nb2 = cell.get_notebook(bufnr)
      if nb2 then
        _last_win_width = vim.api.nvim_win_get_width(0)
        cell.sync_sources_from_buf(bufnr, nil)
        cell.render(bufnr, nb2)
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinEnter", {
    buffer = bufnr,
    callback = rerender_if_width_changed,
  })

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
  -- Double vim.schedule: first tick lets kernel.start and other BufReadCmd
  -- deferrals run; second tick fires attach_lsp with the notebook buffer
  -- reliably current so nvim_exec_autocmds("FileType") targets the right buf.
  vim.schedule(function()
    vim.schedule(function()
      attach_lsp(bufnr)
    end)
  end)

  -- Filter LSP diagnostics that fall inside markdown cell ranges.
  --
  -- The buffer filetype matches the notebook kernel language, so the
  -- attached LSP publishes diagnostics for the whole buffer.  Markdown
  -- prose (English sentences,
  -- bullet points, etc.) is not Python code and produces false "undefined
  -- name" / syntax errors.  After every diagnostic publish cycle, walk each
  -- LSP client's namespace and drop diagnostics whose line falls inside a
  -- markdown cell.
  --
  -- _in_diag_filter prevents re-entrant loops: vim.diagnostic.set() fires
  -- DiagnosticChanged synchronously, so the guard must be set before the
  -- inner vim.schedule and cleared after the set() call returns.
  local _in_diag_filter = false
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    buffer = bufnr,
    callback = function()
      if _in_diag_filter then
        return
      end
      _in_diag_filter = true
      vim.schedule(function()
        -- Bail out early when LSP diagnostic namespace lookup is unavailable
        -- (Neovim < 0.9) or when there are no markdown cells to filter.
        if not (vim.lsp.diagnostic and vim.lsp.diagnostic.get_namespace) then
          _in_diag_filter = false
          return
        end

        -- Build markdown cell ranges from current extmarks.
        local cell_ns = cell.namespace()
        local md_ranges = {}
        for _, cs in ipairs(cell.get_cells(bufnr)) do
          if cs.cell_type == "markdown" then
            local sm = vim.api.nvim_buf_get_extmark_by_id(bufnr, cell_ns, cs.start_mark, {})
            local em = vim.api.nvim_buf_get_extmark_by_id(bufnr, cell_ns, cs.end_mark, {})
            md_ranges[#md_ranges + 1] = { sm[1] or 0, em[1] or 0 }
          end
        end

        if #md_ranges == 0 then
          _in_diag_filter = false
          return
        end

        local function in_markdown(lnum)
          for _, r in ipairs(md_ranges) do
            if lnum >= r[1] and lnum <= r[2] then
              return true
            end
          end
          return false
        end

        -- Filter each LSP client's diagnostics for this buffer.
        local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients
        for _, client in ipairs(get_clients({ bufnr = bufnr })) do
          local diag_ns = vim.lsp.diagnostic.get_namespace(client.id)
          local diags = vim.diagnostic.get(bufnr, { namespace = diag_ns })
          local filtered = {}
          local removed = 0
          for _, d in ipairs(diags) do
            if in_markdown(d.lnum) then
              removed = removed + 1
            else
              filtered[#filtered + 1] = d
            end
          end
          if removed > 0 then
            -- set() fires DiagnosticChanged synchronously; the guard above
            -- ensures we do not recurse.
            vim.diagnostic.set(diag_ns, bufnr, filtered)
          end
        end

        _in_diag_filter = false
      end)
    end,
  })

  -- Mark buffer as not modified after initial load.
  vim.bo[bufnr].modified = false

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
    vim.bo[bufnr].modified = false
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
