--- jupytervim.commands
--- Registers all :Jupyter* user-facing commands.
--- Called once from init.lua during setup().

local M = {}

function M.setup()
  -- ── Notebook commands ──────────────────────────────────────────────────

  vim.api.nvim_create_user_command("JupyterOpen", function(args)
    local path = args.args ~= "" and args.args or vim.fn.expand("%:p")
    local bufnr = vim.api.nvim_get_current_buf()
    require("jupytervim.notebook_buf").open(path, bufnr)
  end, {
    nargs = "?",
    complete = "file",
    desc    = "Open a .ipynb notebook in the current buffer",
  })

  vim.api.nvim_create_user_command("JupyterSave", function()
    require("jupytervim.notebook_buf").save(vim.api.nvim_get_current_buf())
  end, { desc = "Save the current notebook to disk" })

  -- ── Kernel commands ────────────────────────────────────────────────────

  vim.api.nvim_create_user_command("JupyterKernelStart", function(args)
    local bufnr      = vim.api.nvim_get_current_buf()
    local kernel_name = args.args ~= "" and args.args or nil
    local ok, kernel = pcall(require, "jupytervim.kernel")
    if ok then kernel.start(bufnr, kernel_name) end
  end, {
    nargs = "?",
    desc  = "Start a Jupyter kernel for the current notebook",
  })

  vim.api.nvim_create_user_command("JupyterKernelStop", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, kernel = pcall(require, "jupytervim.kernel")
    if ok then kernel.stop(bufnr) end
  end, { desc = "Stop the kernel for the current notebook" })

  vim.api.nvim_create_user_command("JupyterKernelRestart", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, kernel = pcall(require, "jupytervim.kernel")
    if ok then kernel.restart(bufnr) end
  end, { desc = "Restart the kernel for the current notebook" })

  vim.api.nvim_create_user_command("JupyterKernelInterrupt", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, kernel = pcall(require, "jupytervim.kernel")
    if ok then kernel.interrupt(bufnr) end
  end, { desc = "Send an interrupt signal to the kernel" })

  vim.api.nvim_create_user_command("JupyterKernelInfo", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, kernel = pcall(require, "jupytervim.kernel")
    if ok then kernel.show_info(bufnr) end
  end, { desc = "Show info about the current kernel" })

  -- ── Cell execution commands ────────────────────────────────────────────

  vim.api.nvim_create_user_command("JupyterRun", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, kernel = pcall(require, "jupytervim.kernel")
    if ok then kernel.run_current_cell(bufnr) end
  end, { desc = "Execute the cell under the cursor" })

  vim.api.nvim_create_user_command("JupyterRunAll", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, kernel = pcall(require, "jupytervim.kernel")
    if ok then kernel.run_all(bufnr) end
  end, { desc = "Execute all cells in the notebook" })

  vim.api.nvim_create_user_command("JupyterRunAbove", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, kernel = pcall(require, "jupytervim.kernel")
    if ok then kernel.run_all_above(bufnr) end
  end, { desc = "Execute all cells above the cursor" })

  -- ── Cell editing commands ──────────────────────────────────────────────

  vim.api.nvim_create_user_command("JupyterCellAdd", function()
    local cell_mod = require("jupytervim.cell")
    local bufnr    = vim.api.nvim_get_current_buf()
    local _, idx   = cell_mod.cell_at_cursor(bufnr)
    if idx then cell_mod.add_cell_below(bufnr, idx) end
  end, { desc = "Add a code cell below the cursor" })

  vim.api.nvim_create_user_command("JupyterCellDelete", function()
    local cell_mod = require("jupytervim.cell")
    local bufnr    = vim.api.nvim_get_current_buf()
    local _, idx   = cell_mod.cell_at_cursor(bufnr)
    if idx then cell_mod.delete_cell(bufnr, idx) end
  end, { desc = "Delete the cell under the cursor" })

  -- ── Inspector ──────────────────────────────────────────────────────────

  vim.api.nvim_create_user_command("JupyterInspect", function()
    require("jupytervim.inspector").open(vim.api.nvim_get_current_buf())
  end, { desc = "Open variable inspector for the current notebook" })

  -- ── Misc ───────────────────────────────────────────────────────────────

  vim.api.nvim_create_user_command("JupyterHelp", function()
    require("jupytervim.keymaps").show_help()
  end, { desc = "Show jupytervim keymap help" })
end

return M
