--- ipynb.ui.commands
--- Registers all :Jupyter* user-facing commands.
--- Called once from init.lua during setup().

local M = {}

function M.setup()
  -- ── Notebook commands ──────────────────────────────────────────────────

  vim.api.nvim_create_user_command("IpynbOpen", function(args)
    local path = args.args ~= "" and args.args or vim.fn.expand("%:p")
    local bufnr = vim.api.nvim_get_current_buf()
    require("ipynb.core.notebook_buf").open(path, bufnr)
  end, {
    nargs = "?",
    complete = "file",
    desc = "Open a .ipynb notebook in the current buffer",
  })

  vim.api.nvim_create_user_command("IpynbSave", function()
    require("ipynb.core.notebook_buf").save(vim.api.nvim_get_current_buf())
  end, { desc = "Save the current notebook to disk" })

  -- ── Kernel commands ────────────────────────────────────────────────────

  vim.api.nvim_create_user_command("IpynbKernelStart", function(args)
    local bufnr = vim.api.nvim_get_current_buf()
    local kernel_name = args.args ~= "" and args.args or nil
    local ok, kernel = pcall(require, "ipynb.kernel")
    if ok then
      kernel.start(bufnr, kernel_name)
    end
  end, {
    nargs = "?",
    desc = "Start a Jupyter kernel for the current notebook",
  })

  vim.api.nvim_create_user_command("IpynbKernelStop", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, kernel = pcall(require, "ipynb.kernel")
    if ok then
      kernel.stop(bufnr)
    end
  end, { desc = "Stop the kernel for the current notebook" })

  vim.api.nvim_create_user_command("IpynbKernelRestart", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, kernel = pcall(require, "ipynb.kernel")
    if ok then
      kernel.restart(bufnr)
    end
  end, { desc = "Restart the kernel for the current notebook" })

  vim.api.nvim_create_user_command("IpynbKernelInterrupt", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, kernel = pcall(require, "ipynb.kernel")
    if ok then
      kernel.interrupt(bufnr)
    end
  end, { desc = "Send an interrupt signal to the kernel" })

  vim.api.nvim_create_user_command("IpynbKernelInfo", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, kernel = pcall(require, "ipynb.kernel")
    if ok then
      kernel.show_info(bufnr)
    end
  end, { desc = "Show info about the current kernel" })

  vim.api.nvim_create_user_command("IpynbKernelAttach", function(args)
    local bufnr = vim.api.nvim_get_current_buf()
    local cf = args.args ~= "" and args.args or nil
    local ok, kernel = pcall(require, "ipynb.kernel")
    if ok then
      kernel.attach(bufnr, cf)
    end
  end, {
    nargs = "?",
    complete = "file",
    desc = "Attach to an existing Jupyter kernel via connection file",
  })

  -- ── Cell execution commands ────────────────────────────────────────────

  vim.api.nvim_create_user_command("IpynbRun", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, kernel = pcall(require, "ipynb.kernel")
    if ok then
      kernel.run_current_cell(bufnr)
    end
  end, { desc = "Execute the cell under the cursor" })

  vim.api.nvim_create_user_command("IpynbRunAdvance", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, kernel = pcall(require, "ipynb.kernel")
    if ok then
      kernel.run_cell_and_advance(bufnr)
    end
  end, { desc = "Execute current cell and advance to next (Shift+Enter)" })

  vim.api.nvim_create_user_command("IpynbRunAll", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, kernel = pcall(require, "ipynb.kernel")
    if ok then
      kernel.run_all(bufnr)
    end
  end, { desc = "Execute all cells in the notebook" })

  vim.api.nvim_create_user_command("IpynbRunAbove", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, kernel = pcall(require, "ipynb.kernel")
    if ok then
      kernel.run_all_above(bufnr)
    end
  end, { desc = "Execute all cells above the cursor" })

  vim.api.nvim_create_user_command("IpynbRunBelow", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, kernel = pcall(require, "ipynb.kernel")
    if ok then
      kernel.run_all_below(bufnr)
    end
  end, { desc = "Execute all cells below the cursor" })

  vim.api.nvim_create_user_command("IpynbRunSelection", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, kernel = pcall(require, "ipynb.kernel")
    if ok then
      kernel.run_selection(bufnr)
    end
  end, { range = true, desc = "Execute the visually selected lines" })

  -- ── Cell editing commands ──────────────────────────────────────────────

  vim.api.nvim_create_user_command("IpynbCellAdd", function()
    local cell_mod = require("ipynb.core.cell")
    local bufnr = vim.api.nvim_get_current_buf()
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
  end, { desc = "Add a code cell below the cursor" })

  vim.api.nvim_create_user_command("IpynbCellDelete", function()
    local cell_mod = require("ipynb.core.cell")
    local bufnr = vim.api.nvim_get_current_buf()
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.delete_cell(bufnr, idx)
    end
  end, { desc = "Delete the cell under the cursor" })

  vim.api.nvim_create_user_command("IpynbCellAddMarkdown", function()
    local cell_mod = require("ipynb.core.cell")
    local bufnr = vim.api.nvim_get_current_buf()
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
  end, { desc = "Add a markdown cell below the cursor" })

  vim.api.nvim_create_user_command("IpynbCellAddMarkdownAbove", function()
    local cell_mod = require("ipynb.core.cell")
    local bufnr = vim.api.nvim_get_current_buf()
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
  end, { desc = "Add a markdown cell above the cursor" })

  vim.api.nvim_create_user_command("IpynbCellMoveUp", function()
    local cell_mod = require("ipynb.core.cell")
    local bufnr = vim.api.nvim_get_current_buf()
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.move_cell_up(bufnr, idx)
    end
  end, { desc = "Move the current cell one position up" })

  vim.api.nvim_create_user_command("IpynbCellMoveDown", function()
    local cell_mod = require("ipynb.core.cell")
    local bufnr = vim.api.nvim_get_current_buf()
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.move_cell_down(bufnr, idx)
    end
  end, { desc = "Move the current cell one position down" })

  vim.api.nvim_create_user_command("IpynbCellDuplicate", function()
    local cell_mod = require("ipynb.core.cell")
    local bufnr = vim.api.nvim_get_current_buf()
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.duplicate_cell(bufnr, idx)
    end
  end, { desc = "Duplicate the current cell below" })

  vim.api.nvim_create_user_command("IpynbCellYank", function()
    local cell_mod = require("ipynb.core.cell")
    local bufnr = vim.api.nvim_get_current_buf()
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.yank_cell(bufnr, idx)
    end
  end, { desc = "Yank the current cell into the cell register" })

  vim.api.nvim_create_user_command("IpynbCellPaste", function()
    local cell_mod = require("ipynb.core.cell")
    local bufnr = vim.api.nvim_get_current_buf()
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.paste_cell(bufnr, idx)
    end
  end, { desc = "Paste the yanked cell below the current cell" })

  vim.api.nvim_create_user_command("IpynbCellToggleType", function()
    local cell_mod = require("ipynb.core.cell")
    local bufnr = vim.api.nvim_get_current_buf()
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.toggle_cell_type(bufnr, idx)
    end
  end, { desc = "Toggle current cell type between code and markdown" })

  vim.api.nvim_create_user_command("IpynbCellSplit", function()
    local cell_mod = require("ipynb.core.cell")
    local bufnr = vim.api.nvim_get_current_buf()
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.split_cell(bufnr, idx)
    end
  end, { desc = "Split the current cell at the cursor line" })

  vim.api.nvim_create_user_command("IpynbCellMerge", function()
    local cell_mod = require("ipynb.core.cell")
    local bufnr = vim.api.nvim_get_current_buf()
    local _, idx = cell_mod.cell_at_cursor(bufnr)
    if idx then
      cell_mod.merge_cell_below(bufnr, idx)
    end
  end, { desc = "Merge the current cell with the cell below" })

  -- ── Output commands ───────────────────────────────────────────────────

  vim.api.nvim_create_user_command("IpynbClearOutput", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local cell_mod = require("ipynb.core.cell")
    local cs, _ = cell_mod.cell_at_cursor(bufnr)
    if not cs then
      vim.notify("Cursor is not inside a cell.", vim.log.levels.WARN)
      return
    end
    require("ipynb.kernel.output").clear(bufnr, cs)
    local nb = cell_mod.get_notebook(bufnr)
    if nb and nb.cells[cs.index] then
      nb.cells[cs.index].outputs = {}
    end
  end, { desc = "Clear output for the cell under the cursor" })

  vim.api.nvim_create_user_command("IpynbClearAllOutput", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local cell_mod = require("ipynb.core.cell")
    local output = require("ipynb.kernel.output")
    local cells = cell_mod.get_cells(bufnr)
    local nb = cell_mod.get_notebook(bufnr)
    for _, cs in ipairs(cells) do
      output.clear(bufnr, cs)
      if nb and nb.cells[cs.index] then
        nb.cells[cs.index].outputs = {}
      end
    end
    vim.notify("All cell outputs cleared.", vim.log.levels.INFO)
  end, { desc = "Clear output for every cell in the notebook" })

  -- ── Inspector ──────────────────────────────────────────────────────────

  vim.api.nvim_create_user_command("IpynbInspect", function()
    require("ipynb.ui.inspector").open(vim.api.nvim_get_current_buf())
  end, { desc = "Open variable inspector for the current notebook" })

  -- ── Misc ───────────────────────────────────────────────────────────────

  vim.api.nvim_create_user_command("IpynbHelp", function()
    require("ipynb.ui.keymaps").show_help()
  end, { desc = "Show ipynb keymap help" })
end

return M
