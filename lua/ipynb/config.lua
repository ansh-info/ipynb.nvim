--- ipynb.config
--- Default configuration and user-merge logic.
--- All values here can be overridden via require("ipynb").setup(opts).

local M = {}

---@class IpynbConfig
---@field cell CellConfig
---@field ui UIConfig
---@field keymaps KeymapConfig
---@field image ImageConfig
---@field kernel KernelConfig
---@field notebook NotebookConfig

---@class CellConfig
---@field highlight_cell boolean   Highlight the active cell background
---@field hl_group string          Highlight group for active cell

---@class UIConfig
---@field border_chars BorderChars   Box-drawing chars for cell borders
---@field lang_icons table<string,string>  Language → icon mapping
---@field show_execution_count boolean
---@field show_elapsed_time boolean
---@field output_max_lines integer   Max virt_lines per output block (0 = unlimited)

---@class BorderChars
---@field top_left string
---@field top_right string
---@field bottom_left string
---@field bottom_right string
---@field horizontal string
---@field vertical string

---@class KeymapConfig
---@field enabled boolean          Install default keymaps
---@field run_cell string
---@field run_cell_and_advance string
---@field run_all_above string
---@field run_all_below string
---@field next_cell string
---@field prev_cell string
---@field add_cell_below string
---@field add_cell_above string
---@field delete_cell string
---@field interrupt_kernel string
---@field clear_output string
---@field clear_all_output string
---@field add_markdown_below string
---@field add_markdown_above string

---@class ImageConfig
---@field enabled boolean          Enable image rendering (requires snacks.nvim + unicode placeholder terminal)
---@field max_width integer        Max image width in columns
---@field max_height integer       Max image height in rows

---@class KernelConfig
---@field python_path string       Python executable for kernel_bridge.py
---@field default_kernel string    Default kernel name when starting fresh
---@field auto_start boolean       Auto-start kernel on first run attempt
---@field connection_dir string    Where to look for existing connection files

---@class NotebookConfig
---@field auto_save boolean        Save .ipynb after every cell execution
---@field default_kernel_name string

---@type IpynbConfig
M.defaults = {
  cell = {
    highlight_cell = true,
    hl_group = "CursorLine",
  },

  ui = {
    border_chars = {
      top_left = "╭",
      top_right = "╮",
      bottom_left = "╰",
      bottom_right = "╯",
      horizontal = "─",
      vertical = "│",
    },
    lang_icons = {
      python = "",
      r = "󰟔",
      julia = "",
      javascript = "",
      typescript = "",
      bash = "",
      markdown = "",
      raw = "󰦨",
      [""] = "",
    },
    show_execution_count = true,
    show_elapsed_time = true,
    output_max_lines = 50,
  },

  keymaps = {
    enabled = true,
    run_cell = "<leader>rr",
    run_cell_and_advance = "<leader>rn",
    run_all_above = "<leader>ra",
    run_all_below = "<leader>rb",
    next_cell = "]c",
    prev_cell = "[c",
    add_cell_below = "<leader>co",
    add_cell_above = "<leader>cO",
    delete_cell = "<leader>cd",
    interrupt_kernel = "<leader>ri",
    clear_output = "<leader>cx",
    clear_all_output = "<leader>cX",
    add_markdown_below = "<leader>mo",
    add_markdown_above = "<leader>mO",
  },

  image = {
    enabled = true,
    max_width = 80,
    max_height = 20,
  },

  kernel = {
    python_path = "python3",
    default_kernel = "python3",
    auto_start = true,
    connection_dir = vim.fn.expand("~/.local/share/jupyter/runtime"),
  },

  notebook = {
    auto_save = false,
    default_kernel_name = "python3",
  },
}

--- Merged active config (set once by setup()).
---@type IpynbConfig
M.options = {}

--- Deep-merge user options on top of defaults.
--- Only keys present in defaults are accepted (unknown keys are ignored).
---@param opts table|nil
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

--- Convenience getter — returns the active config, initialising with defaults
--- if setup() was never called.
---@return IpynbConfig
function M.get()
  if vim.tbl_isempty(M.options) then
    M.setup()
  end
  return M.options
end

return M
