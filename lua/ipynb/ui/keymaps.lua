--- ipynb.ui.keymaps
--- Default buffer-local keymaps installed when a .ipynb file is opened.
--- All mappings are buffer-local so they don't leak into other buffers.

local config = require("ipynb.config")
local utils = require("ipynb.utils")

local M = {}

--- Install keymaps for a given buffer.
--- This is called once per buffer from the BufReadCmd autocmd.
---@param bufnr integer
function M.attach(bufnr)
  local cfg = config.get()
  if not cfg.keymaps.enabled then
    return
  end

  local km = cfg.keymaps
  local opts = { buffer = bufnr, silent = true, noremap = true }

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
  end

  -- ── Cell navigation ────────────────────────────────────────────────────
  map("n", km.next_cell, function()
    require("ipynb.core.cell").goto_next_cell(bufnr)
  end, "Jupyter: next cell")

  map("n", km.prev_cell, function()
    require("ipynb.core.cell").goto_prev_cell(bufnr)
  end, "Jupyter: previous cell")

  -- ── Cell execution ─────────────────────────────────────────────────────
  map({ "n", "i" }, km.run_cell, function()
    local ok, kernel = pcall(require, "ipynb.kernel")
    if ok then
      kernel.run_current_cell(bufnr)
    else
      utils.warn("Kernel module not yet available.")
    end
  end, "Jupyter: run current cell")

  map({ "n", "i" }, km.run_cell_and_advance, function()
    local ok, kernel = pcall(require, "ipynb.kernel")
    if ok then
      kernel.run_cell_and_advance(bufnr)
    else
      utils.warn("Kernel module not yet available.")
    end
  end, "Jupyter: run cell and advance")

  map("n", km.run_all_above, function()
    local ok, kernel = pcall(require, "ipynb.kernel")
    if ok then
      kernel.run_all_above(bufnr)
    end
  end, "Jupyter: run all cells above")

  map("n", km.run_all_below, function()
    local ok, kernel = pcall(require, "ipynb.kernel")
    if ok then
      kernel.run_all_below(bufnr)
    end
  end, "Jupyter: run all cells below cursor")

  -- ── Kernel control ─────────────────────────────────────────────────────
  map("n", km.interrupt_kernel, function()
    local ok, kernel = pcall(require, "ipynb.kernel")
    if ok then
      kernel.interrupt(bufnr)
    end
  end, "Jupyter: interrupt kernel")

  -- ── Cell editing ───────────────────────────────────────────────────────
  map("n", km.add_cell_below, function()
    local cell_mod = require("ipynb.core.cell")
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if not idx then
      local nb = cell_mod.get_notebook(bufnr)
      if nb and #nb.cells == 0 then
        idx = 0
      end
    end
    if idx then
      cell_mod.add_cell_below(bufnr, idx)
    end
  end, "Jupyter: add cell below")

  map("n", km.add_cell_above, function()
    local cell_mod = require("ipynb.core.cell")
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if not idx then
      local nb = cell_mod.get_notebook(bufnr)
      if nb and #nb.cells == 0 then
        idx = 1
      end
    end
    if idx then
      cell_mod.add_cell_above(bufnr, idx)
    end
  end, "Jupyter: add cell above")

  map("n", km.delete_cell, function()
    local cell_mod = require("ipynb.core.cell")
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.delete_cell(bufnr, idx)
    end
  end, "Jupyter: delete current cell")

  map("n", km.clear_output, function()
    vim.cmd("IpynbClearOutput")
  end, "Jupyter: clear current cell output")

  map("n", km.clear_all_output, function()
    vim.cmd("IpynbClearAllOutput")
  end, "Jupyter: clear all cell outputs")

  map("n", km.add_markdown_below, function()
    local cell_mod = require("ipynb.core.cell")
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if not idx then
      local nb = cell_mod.get_notebook(bufnr)
      if nb and #nb.cells == 0 then
        idx = 0
      end
    end
    if idx then
      cell_mod.add_cell_below(bufnr, idx, "markdown")
    end
  end, "Jupyter: add markdown cell below")

  map("n", km.add_markdown_above, function()
    local cell_mod = require("ipynb.core.cell")
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if not idx then
      local nb = cell_mod.get_notebook(bufnr)
      if nb and #nb.cells == 0 then
        idx = 1
      end
    end
    if idx then
      cell_mod.add_cell_above(bufnr, idx, "markdown")
    end
  end, "Jupyter: add markdown cell above")

  map("n", km.move_cell_up, function()
    local cell_mod = require("ipynb.core.cell")
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.move_cell_up(bufnr, idx)
    end
  end, "Jupyter: move cell up")

  map("n", km.move_cell_down, function()
    local cell_mod = require("ipynb.core.cell")
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.move_cell_down(bufnr, idx)
    end
  end, "Jupyter: move cell down")

  map("n", km.duplicate_cell, function()
    local cell_mod = require("ipynb.core.cell")
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.duplicate_cell(bufnr, idx)
    end
  end, "Jupyter: duplicate cell")

  map("n", km.yank_cell, function()
    local cell_mod = require("ipynb.core.cell")
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.yank_cell(bufnr, idx)
    end
  end, "Jupyter: yank cell")

  map("n", km.paste_cell, function()
    local cell_mod = require("ipynb.core.cell")
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.paste_cell(bufnr, idx)
    end
  end, "Jupyter: paste cell below")

  map("n", km.toggle_cell_type, function()
    local cell_mod = require("ipynb.core.cell")
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.toggle_cell_type(bufnr, idx)
    end
  end, "Jupyter: toggle cell type code/markdown")

  map("n", km.split_cell, function()
    local cell_mod = require("ipynb.core.cell")
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.split_cell(bufnr, idx)
    end
  end, "Jupyter: split cell at cursor")

  map("n", km.merge_cell, function()
    local cell_mod = require("ipynb.core.cell")
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.merge_cell_below(bufnr, idx)
    end
  end, "Jupyter: merge cell with cell below")

  -- ── Save ───────────────────────────────────────────────────────────────
  -- Override :w so it saves back to .ipynb format.
  map("n", "<leader>w", function()
    require("ipynb.core.notebook_buf").save(bufnr)
  end, "Jupyter: save notebook")

  -- Also hook ZZ / :wq equivalents through the same path.
  vim.api.nvim_buf_create_user_command(bufnr, "IpynbSave", function()
    require("ipynb.core.notebook_buf").save(bufnr)
  end, { desc = "Save Jupyter notebook to disk" })

  -- ── Help overlay ───────────────────────────────────────────────────────
  map("n", "<leader>jh", function()
    M.show_help()
  end, "Jupyter: show keymap help")
end

--- Show a floating help window listing all keymaps.
function M.show_help()
  local cfg = config.get()
  local km = cfg.keymaps

  local lines = {
    " ipynb — keymaps ",
    string.rep("─", 40),
    "",
    "  Navigation",
    "  " .. km.next_cell .. "   → next cell",
    "  " .. km.prev_cell .. "   → previous cell",
    "",
    "  Execution",
    "  " .. km.run_cell .. "   → run current cell",
    "  " .. km.run_cell_and_advance .. "  → run cell and advance",
    "  " .. km.run_all_above .. "   → run all cells above",
    "  " .. km.run_all_below .. "   → run all cells below",
    "  " .. km.interrupt_kernel .. " → interrupt kernel",
    "",
    "  Editing",
    "  " .. km.add_cell_below .. "  → add cell below",
    "  " .. km.add_cell_above .. "  → add cell above",
    "  " .. km.delete_cell .. "  → delete cell",
    "  " .. km.duplicate_cell .. "  → duplicate cell",
    "  " .. km.yank_cell .. "  → yank cell",
    "  " .. km.paste_cell .. "  → paste cell below",
    "  " .. km.toggle_cell_type .. "  → toggle code/markdown",
    "  " .. km.split_cell .. "  → split cell at cursor",
    "  " .. km.merge_cell .. "  → merge cell with below",
    "  " .. km.move_cell_up .. "  → move cell up",
    "  " .. km.move_cell_down .. "  → move cell down",
    "  " .. km.add_markdown_below .. "  → add markdown cell below",
    "  " .. km.add_markdown_above .. "  → add markdown cell above",
    "  " .. km.clear_output .. "  → clear cell output",
    "  " .. km.clear_all_output .. "  → clear all outputs",
    "",
    "  File",
    "  <leader>w → save notebook",
    "",
    "  Press q or <Esc> to close.",
  }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"

  local width = math.max(1, math.min(44, vim.o.columns - 4))
  local height = math.max(1, math.min(#lines, vim.o.lines - 4))
  local row = math.max(0, math.floor((vim.o.lines - height) / 2))
  local col = math.max(0, math.floor((vim.o.columns - width) / 2))

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " Jupyter Keymaps ",
    title_pos = "center",
  })

  -- Close on q or Esc.
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function()
      vim.api.nvim_win_close(win, true)
    end, { buffer = buf, noremap = true, silent = true })
  end

  vim.api.nvim_set_option_value("winhl", "Normal:FloatBorder", { win = win })
end

return M
