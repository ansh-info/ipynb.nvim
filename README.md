# ipynb

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
- [Contributing](#contributing)

## Requirements

- Neovim >= 0.10.0
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- Python >= 3.12
- [uv](https://github.com/astral-sh/uv) (recommended) or python3 (built-in venv fallback)

**Optional - image rendering**

- [3rd/image.nvim](https://github.com/3rd/image.nvim)
- Kitty, Ghostty, or WezTerm terminal (Kitty graphics protocol), or `ueberzugpp`

**Optional - richer markdown cells**

- [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim)

**Optional - completion**

- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

## Installation

### lazy.nvim

```lua
return {
  {
    "ansh-info/ipynb.nvim",
    lazy = false,
    build = "uv sync --project python/ || (python3 -m venv python/.venv && python/.venv/bin/pip install ./python/)",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
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
      "nvim-treesitter/nvim-treesitter",
      { "3rd/image.nvim", opts = {} },
      { "MeanderingProgrammer/render-markdown.nvim", opts = {} },
      { "hrsh7th/nvim-cmp" },
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
<leader>r      run the cell under the cursor
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
| `:IpynbOpen [path]` | Open a notebook |
| `:IpynbSave` | Save the current notebook |
| `:IpynbKernelStart [name]` | Start a kernel (`python3` default) |
| `:IpynbKernelStop` | Stop the kernel |
| `:IpynbKernelRestart` | Restart kernel and clear all output |
| `:IpynbKernelInterrupt` | Send interrupt (Ctrl-C) |
| `:IpynbKernelInfo` | Show kernel status window |
| `:IpynbRun` | Run current cell |
| `:IpynbRunAll` | Run all cells |
| `:IpynbRunAbove` | Run all cells above cursor |
| `:IpynbCellAdd` | Add code cell below |
| `:IpynbCellDelete` | Delete current cell |
| `:IpynbInspect` | Open variable inspector |
| `:IpynbHelp` | Show keymap reference |

## Configuration

The following is the default configuration. Pass any subset of these to `opts`
or `setup()` to override.

```lua
require("ipynb").setup({
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

Issues and pull requests are welcome at https://github.com/ansh-info/ipynb.nvim.

## License

MIT - see [LICENSE](LICENSE).
