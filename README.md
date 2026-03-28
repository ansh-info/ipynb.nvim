# jupytervim

Neovim plugin for editing Jupyter notebooks (`.ipynb`) natively — Colab-style cell
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
- [Keymaps](#keymaps)
- [Commands](#commands)
- [Configuration](#configuration)
- [Contributing](#contributing)

## Requirements

- Neovim >= 0.10.0
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- Python >= 3.12
- [uv](https://github.com/astral-sh/uv) (recommended) or pip3

**Optional — image rendering**

- [3rd/image.nvim](https://github.com/3rd/image.nvim)
- Kitty, Ghostty, or WezTerm terminal (Kitty graphics protocol), or `ueberzugpp`

**Optional — richer markdown cells**

- [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim)

**Optional — completion**

- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

## Installation

### lazy.nvim

```lua
{
  "ansh-info/jupytervim",
  lazy = false,
  build = "uv sync --project python/ || pip3 install ./python/",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {},
}
```

> `lazy = false` is required — the plugin must load before any buffer is opened
> so it can intercept `.ipynb` files via `BufReadCmd`.

> The `build` hook installs the Python kernel bridge dependencies
> (`jupyter_client`, `ipykernel`, `nbformat`) on first install and on updates.
> It tries `uv` first for an isolated venv; falls back to `pip3` if `uv` is not
> installed. Run `:Lazy build jupytervim` to re-run it manually if needed.

**With optional dependencies:**

```lua
{
  "ansh-info/jupytervim",
  lazy = false,
  build = "uv sync --project python/ || pip3 install ./python/",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    { "3rd/image.nvim", opts = {} },
    { "MeanderingProgrammer/render-markdown.nvim", opts = {} },
    { "hrsh7th/nvim-cmp" },
  },
  opts = {},
}
```

### packer.nvim

```lua
use {
  "ansh-info/jupytervim",
  run = "uv sync --project python/ || pip3 install ./python/",
  config = function()
    require("jupytervim").setup({})
  end,
}
```

## Setup

Setup is called automatically when you pass `opts = {}` to lazy.nvim. If you
manage setup yourself:

```lua
require("jupytervim").setup({})
```

## Usage

Open any `.ipynb` file — the plugin renders it automatically:

```
nvim my_notebook.ipynb
```

The kernel starts automatically when you run your first cell. No manual
`:JupyterKernelStart` needed unless `auto_start` is disabled.

```
<leader>r      run the cell under the cursor
]c / [c        jump to next / previous cell
<leader>ji     open variable inspector
```

## Keymaps

All keymaps are buffer-local and only active inside `.ipynb` buffers.
Press `<leader>jh` to show the help overlay at any time.

| Key | Action |
|---|---|
| `<leader>r` | Run current cell |
| `<leader>ra` | Run all cells above cursor |
| `<leader>rb` | Run all cells from cursor downwards |
| `<leader>ri` | Interrupt kernel |
| `]c` | Next cell |
| `[c` | Previous cell |
| `<leader>co` | Add code cell below |
| `<leader>cO` | Add code cell above |
| `<leader>cd` | Delete current cell |
| `<leader>w` | Save notebook |
| `<leader>ji` | Variable inspector |
| `<leader>jh` | Keymap help overlay |
| `<C-x><C-o>` | Kernel completions (insert mode) |

## Commands

| Command | Description |
|---|---|
| `:JupyterOpen [path]` | Open a notebook |
| `:JupyterSave` | Save the current notebook |
| `:JupyterKernelStart [name]` | Start a kernel (`python3` default) |
| `:JupyterKernelStop` | Stop the kernel |
| `:JupyterKernelRestart` | Restart kernel and clear all output |
| `:JupyterKernelInterrupt` | Send interrupt (Ctrl-C) |
| `:JupyterKernelInfo` | Show kernel status window |
| `:JupyterRun` | Run current cell |
| `:JupyterRunAll` | Run all cells |
| `:JupyterRunAbove` | Run all cells above cursor |
| `:JupyterCellAdd` | Add code cell below |
| `:JupyterCellDelete` | Delete current cell |
| `:JupyterInspect` | Open variable inspector |
| `:JupyterHelp` | Show keymap reference |

## Configuration

The following is the default configuration. Pass any subset of these to `opts`
or `setup()` to override.

```lua
require("jupytervim").setup({
  kernel = {
    default_kernel = "python3",
    auto_start     = true,       -- start kernel automatically on first run
    python_path    = "python3",  -- fallback if uv venv is not found
  },
  ui = {
    show_execution_count = true,
    show_elapsed_time    = true,
    output_max_lines     = 50,   -- max output lines per cell; 0 = unlimited
  },
  image = {
    enabled    = true,
    backend    = "auto",         -- "kitty" | "ueberzug" | "sixel" | "auto"
    max_width  = 80,
    max_height = 20,
  },
  keymaps = {
    enabled          = true,
    run_cell         = "<leader>r",
    run_all_above    = "<leader>ra",
    run_all_below    = "<leader>rb",
    next_cell        = "]c",
    prev_cell        = "[c",
    add_cell_below   = "<leader>co",
    add_cell_above   = "<leader>cO",
    delete_cell      = "<leader>cd",
    interrupt_kernel = "<leader>ri",
  },
  notebook = {
    auto_save = false,
  },
})
```

## Contributing

Issues and pull requests are welcome at https://github.com/ansh-info/jupytervim.

## License

MIT — see [LICENSE](LICENSE).
