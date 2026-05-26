# ipynb

[![CI](https://github.com/ansh-info/ipynb.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/ansh-info/ipynb.nvim/actions/workflows/ci.yml)

Neovim plugin for editing Jupyter notebooks (`.ipynb`) natively - Colab-style cell
rendering, full Vim modal editing, live kernel execution, and inline output.

```
╭── [ python · [3] ────────────────────────────────────────╮
  import numpy as np
  x = np.linspace(0, 10, 100)
  print(x.mean())
╰── ✓ 0.12s ───────────────────────────────────────────────╯
  5.0
```

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Setup](#setup)
- [Usage](#usage)
  - [Using packages from a project venv](#using-packages-from-a-project-venv-numpy-matplotlib-etc)
- [Keymaps](#keymaps)
- [Commands](#commands)
- [Configuration](#configuration)
- [Statusline](#statusline)
- [Contributing](#contributing)

## Requirements

- Neovim >= 0.9
- Python >= 3.12
- [uv](https://github.com/astral-sh/uv) (recommended) or python3 (built-in venv fallback)

**Required for image rendering** (matplotlib plots, inline PNG/JPEG/SVG)

- [folke/snacks.nvim](https://github.com/folke/snacks.nvim) with `image` module enabled
- A terminal with Kitty graphics protocol **unicode placeholder** support:

| Terminal | Supported |
|---|---|
| [kitty](https://sw.kovidgoyal.net/kitty/) >= 0.28 | yes |
| [Ghostty](https://ghostty.org/) | yes |
| [WezTerm](https://wezfurlong.org/wezterm/) | yes |
| tmux (wrapping any of the above) | yes - see note below |
| alacritty, iTerm2, others | no |

- **tmux users:** add to `~/.tmux.conf` and restart tmux:
  ```
  set -gq allow-passthrough on
  set -g visual-activity off
  set-option -g focus-events on
  ```

**Optional - completion**

- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

**Optional - language icons in cell borders**

- [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)

## Installation

### lazy.nvim

```lua
return {
  {
    "ansh-info/ipynb.nvim",
    lazy = false,
    build = "uv sync --project python/ || (python3 -m venv python/.venv && python/.venv/bin/pip install ./python/)",
    opts = {},
  },
}
```

> `lazy = false` is required - the plugin must load before any buffer is opened
> so it can intercept `.ipynb` files via `BufReadCmd`.

> The `build` hook installs the Python kernel bridge dependencies
> (`jupyter_client`, `ipykernel`, `nbformat`) into an isolated venv at
> `python/.venv/`. It tries `uv` first; if `uv` is not installed it falls back
> to the standard `python3 -m venv`. Run `:Lazy build ipynb` to re-run it
> manually after updates.

**With optional dependencies:**

```lua
return {
  {
    "ansh-info/ipynb.nvim",
    lazy = false,
    build = "uv sync --project python/ || (python3 -m venv python/.venv && python/.venv/bin/pip install ./python/)",
    dependencies = {
      {
        "folke/snacks.nvim",
        opts = {
          image = { enabled = true },
        },
      },
      { "hrsh7th/nvim-cmp" },
      { "nvim-tree/nvim-web-devicons" },
    },
    opts = {},
  },
}
```

### packer.nvim

```lua
use({
  "ansh-info/ipynb.nvim",
  run = "uv sync --project python/ || (python3 -m venv python/.venv && python/.venv/bin/pip install ./python/)",
  config = function()
    require("ipynb").setup({})
  end,
})
```

## Setup

Setup is called automatically when you pass `opts = {}` to lazy.nvim. If you
manage setup yourself:

```lua
require("ipynb").setup({})
```

## Usage

Open any `.ipynb` file - the plugin renders it automatically:

```
nvim my_notebook.ipynb
```

The kernel starts automatically when you run your first cell. No manual
`:IpynbKernelStart` needed unless `auto_start` is disabled.

```
<leader>rr     run the cell under the cursor
]c / [c        jump to next / previous cell
<leader>ji     open variable inspector
```

### Using packages from a project venv (numpy, matplotlib, etc.)

By default the kernel runs on the plugin's own Python, which only has the
bridge dependencies (`jupyter_client`, `ipykernel`, `nbformat`). To use
your own packages, activate your project venv **before** launching Neovim:

```bash
# One-time setup per venv - ipykernel is required for the kernel to launch
uv pip install ipykernel numpy matplotlib   # or: pip install ...

# Then just activate and open Neovim as normal
source .venv/bin/activate
nvim my_notebook.ipynb
```

The plugin auto-detects `$VIRTUAL_ENV` (uv/venv) and `$CONDA_PREFIX`
(conda) and uses that Python as the kernel. No config change needed.

> **Why ipykernel?** The kernel is a separate process launched as
> `python -m ipykernel_launcher`. That process must be able to import
> `ipykernel`, so it needs to be installed in your venv alongside your
> packages. If it is missing you will see an error in `:messages` with
> install instructions.

## Keymaps

All keymaps are buffer-local and only active inside `.ipynb` buffers.
Press `<leader>jh` to show the help overlay at any time.

| Key | Action |
|---|---|
| `<leader>rr` | Run current cell |
| `<leader>rn` | Run cell and advance to next (Shift+Enter) |
| `<leader>ra` | Run all cells above cursor |
| `<leader>rb` | Run all cells from cursor downwards |
| `<leader>ri` | Interrupt kernel |
| `]c` | Next cell |
| `[c` | Previous cell |
| `<leader>co` | Add code cell below |
| `<leader>cO` | Add code cell above |
| `<leader>mo` | Add markdown cell below |
| `<leader>mO` | Add markdown cell above |
| `<leader>cd` | Delete current cell |
| `<leader>ck` | Move current cell up |
| `<leader>cj` | Move current cell down |
| `<leader>cc` | Duplicate current cell |
| `<leader>cy` | Yank cell into cell register |
| `<leader>cv` | Paste yanked cell below |
| `<leader>ct` | Toggle cell type (code/markdown) |
| `<leader>cs` | Split cell at cursor line |
| `<leader>cm` | Merge cell with the cell below |
| `<leader>cx` | Clear current cell output |
| `<leader>cX` | Clear all cell outputs |
| `u` | Smart undo (text edits or structural cell ops) |
| `<C-r>` | Smart redo (text edits or structural cell ops) |
| `<leader>w` | Save notebook |
| `<leader>ji` | Variable inspector |
| `<leader>jh` | Keymap help overlay |
| `<C-x><C-o>` | Kernel completions (insert mode) |

## Commands

| Command | Description |
|---|---|
| `:IpynbOpen [path]` | Open a notebook |
| `:IpynbSave` | Save the current notebook |
| `:IpynbKernelStart [name]` | Start a kernel (`python3` default) |
| `:IpynbKernelStop` | Stop the kernel |
| `:IpynbKernelRestart` | Restart kernel and clear all output |
| `:IpynbKernelInterrupt` | Send interrupt (Ctrl-C) |
| `:IpynbKernelInfo` | Show kernel status window |
| `:IpynbKernelAttach [file]` | Attach to an existing kernel via connection file |
| `:IpynbRun` | Run current cell |
| `:IpynbRunAdvance` | Run cell and advance to next |
| `:IpynbRunAll` | Run all cells |
| `:IpynbRunAbove` | Run all cells above cursor |
| `:IpynbRunBelow` | Run all cells from cursor downwards |
| `:IpynbCellAdd` | Add code cell below |
| `:IpynbCellDelete` | Delete current cell |
| `:IpynbCellAddMarkdown` | Add markdown cell below |
| `:IpynbCellAddMarkdownAbove` | Add markdown cell above |
| `:IpynbCellMoveUp` | Move current cell up |
| `:IpynbCellMoveDown` | Move current cell down |
| `:IpynbCellDuplicate` | Duplicate current cell below |
| `:IpynbCellYank` | Yank cell into cell register |
| `:IpynbCellPaste` | Paste yanked cell below |
| `:IpynbCellToggleType` | Toggle cell type (code/markdown) |
| `:IpynbCellSplit` | Split cell at cursor line |
| `:IpynbCellMerge` | Merge cell with the cell below |
| `:IpynbClearOutput` | Clear output for cell under cursor |
| `:IpynbClearAllOutput` | Clear output for every cell |
| `:IpynbInspect` | Open variable inspector |
| `:IpynbHelp` | Show keymap reference |

## Configuration

The following is the default configuration. Pass any subset of these to `opts`
or `setup()` to override.

```lua
require("ipynb").setup({
  cell = {
    highlight_cell = true,       -- highlight the active cell background
    hl_group       = "CursorLine",
  },
  kernel = {
    default_kernel   = "python3",
    auto_start       = true,       -- start kernel automatically on first run
    python_path      = "python3",  -- fallback if uv venv is not found
    restart_on_crash = false,      -- auto-restart kernel after unexpected crash
    connection_dir   = "~/.local/share/jupyter/runtime",
  },
  ui = {
    show_execution_count = true,
    show_elapsed_time    = true,
    output_max_lines     = 50,   -- max output lines per cell; 0 = unlimited
  },
  image = {
    enabled    = true,           -- requires snacks.nvim + unicode placeholder terminal
    max_width  = 80,
    max_height = 20,
  },
  keymaps = {
    enabled          = true,
    run_cell              = "<leader>rr",
    run_cell_and_advance  = "<leader>rn",
    run_all_above         = "<leader>ra",
    run_all_below    = "<leader>rb",
    next_cell        = "]c",
    prev_cell        = "[c",
    add_cell_below   = "<leader>co",
    add_cell_above   = "<leader>cO",
    delete_cell      = "<leader>cd",
    interrupt_kernel = "<leader>ri",
    clear_output        = "<leader>cx",
    clear_all_output    = "<leader>cX",
    add_markdown_below  = "<leader>mo",
    add_markdown_above  = "<leader>mO",
    move_cell_up        = "<leader>ck",
    move_cell_down      = "<leader>cj",
    duplicate_cell      = "<leader>cc",
    yank_cell           = "<leader>cy",
    paste_cell          = "<leader>cv",
    toggle_cell_type    = "<leader>ct",
    split_cell          = "<leader>cs",
    merge_cell          = "<leader>cm",
  },
  notebook = {
    auto_save            = false,
    default_kernel_name  = "python3",
  },
})
```

## Statusline

`require("ipynb").statusline()` returns a formatted string showing the kernel
name and status for the current buffer. Returns an empty string for non-notebook
buffers so the component disappears outside `.ipynb` files.

```
⬤ python3 [idle]       -- kernel ready
⬤ python3 [busy]       -- cell executing
⬤ python3 [starting]   -- kernel booting
⬤ python3 [stopped]    -- kernel dead or not started
```

`require("ipynb").statusline_hl()` returns a highlight group name matching the
status (`DiagnosticOk`, `DiagnosticWarn`, `DiagnosticInfo`, `DiagnosticError`).

### lualine

```lua
require("lualine").setup({
  sections = {
    lualine_x = {
      {
        function() return require("ipynb").statusline() end,
        cond = function() return require("ipynb").statusline() ~= "" end,
        color = function()
          return { fg = vim.fn.synIDattr(vim.fn.hlID(require("ipynb").statusline_hl()), "fg#") }
        end,
      },
    },
  },
})
```

### heirline

```lua
local IpynbStatus = {
  condition = function() return require("ipynb").statusline() ~= "" end,
  provider = function() return " " .. require("ipynb").statusline() .. " " end,
  hl = function() return require("ipynb").statusline_hl() end,
}
```

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for
development setup, test instructions, and the contribution workflow.

## License

MIT - see [LICENSE](LICENSE).
