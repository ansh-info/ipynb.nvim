# jupytervim

A Neovim plugin that brings a Google Colab-like Jupyter notebook experience
directly into Neovim — with full Vim modal editing, inline cell output,
and image/plot rendering via the Kitty graphics protocol.

```
╭── [py] python · [3] ─────────────────────────────────────╮
  import numpy as np
  import matplotlib.pyplot as plt

  x = np.linspace(0, 2 * np.pi, 200)
  plt.plot(x, np.sin(x))
  plt.show()
╰── ✓ 0.42s ────────────────────────────────────────────────╯
  [sinusoidal plot rendered inline via Kitty protocol]
```

---

## Features

| Feature | Status |
|---|---|
| Open `.ipynb` files natively in Neovim | ✅ Phase 1 |
| Colab-style cell borders and decorations | ✅ Phase 1 |
| Full Vim modal editing (insert, normal, visual) inside cells | ✅ Phase 1 |
| Cell navigation (`]c` / `[c`) | ✅ Phase 1 |
| Add / delete cells | ✅ Phase 1 |
| Save back to `.ipynb` | ✅ Phase 1 |
| Jupyter kernel execution | ✅ Phase 2 |
| Text / error output as inline virtual lines | ✅ Phase 2 |
| Image / plot rendering (Kitty / ueberzugpp) | ✅ Phase 3 |
| Markdown cell rendering | 🔜 Phase 4 |
| Kernel completions (LSP-style) | 🔜 Phase 4 |

---

## Requirements

### Neovim

- Neovim **0.10+** (for `virt_lines` and `virt_text_pos = "inline"`)
- `nvim-treesitter` — syntax highlighting inside cells

### Optional (for image rendering — Phase 3)

- `3rd/image.nvim` — image rendering backend
- Terminal with Kitty graphics protocol: **Kitty**, **Ghostty**, **WezTerm**
- Or `ueberzugpp` for any other terminal (X11/Wayland)

### Python (Phase 2 onwards)

```bash
pip install jupyter_client nbformat ipykernel
```

---

## Installation

### lazy.nvim

```lua
{
  "ansh-info/jupytervim",
  ft = "ipynb",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    -- Optional: image rendering
    { "3rd/image.nvim", opts = {} },
  },
  opts = {
    -- All options are optional; defaults shown below.
    keymaps = {
      enabled       = true,
      run_cell      = "<leader>r",
      next_cell     = "]c",
      prev_cell     = "[c",
      add_cell_below = "<leader>co",
      add_cell_above = "<leader>cO",
      delete_cell   = "<leader>cd",
    },
    ui = {
      show_execution_count = true,
      show_elapsed_time    = true,
    },
    image = {
      enabled  = true,
      backend  = "auto",   -- "kitty" | "ueberzug" | "sixel" | "auto"
    },
    notebook = {
      auto_save = false,
    },
  },
}
```

### packer.nvim

```lua
use {
  "ansh-info/jupytervim",
  config = function()
    require("jupytervim").setup({})
  end,
}
```

---

## Default Keymaps

| Key | Action |
|---|---|
| `]c` | Next cell |
| `[c` | Previous cell |
| `<leader>r` | Run current cell |
| `<leader>ra` | Run all cells above |
| `<leader>rb` | Run all cells below |
| `<leader>ri` | Interrupt kernel |
| `<leader>co` | Add cell below |
| `<leader>cO` | Add cell above |
| `<leader>cd` | Delete current cell |
| `<leader>w` | Save notebook |
| `<leader>jh` | Show keymap help |

---

## Commands

| Command | Description |
|---|---|
| `:JupyterOpen [path]` | Open a notebook in the current buffer |
| `:JupyterSave` | Save the notebook to disk |
| `:JupyterKernelStart [name]` | Start a kernel (Phase 2) |
| `:JupyterKernelStop` | Stop the kernel |
| `:JupyterKernelRestart` | Restart the kernel |
| `:JupyterKernelInterrupt` | Interrupt running execution |
| `:JupyterRun` | Execute the cell under the cursor |
| `:JupyterRunAll` | Execute all cells |
| `:JupyterRunAbove` | Execute all cells above cursor |
| `:JupyterCellAdd` | Add a code cell below |
| `:JupyterCellDelete` | Delete the cell under cursor |
| `:JupyterHelp` | Show keymap reference |

---

## Architecture

```
jupytervim/
├── lua/jupytervim/
│   ├── init.lua          # Public API, setup(), autocmd registration
│   ├── config.lua        # Default config + user-merge
│   ├── notebook.lua      # .ipynb parse / serialise (nbformat 3 & 4)
│   ├── notebook_buf.lua  # Buffer lifecycle (open, save, sync)
│   ├── cell.lua          # Cell rendering, extmarks, navigation, mutation
│   ├── keymaps.lua       # Buffer-local keymap installation
│   ├── commands.lua      # :Jupyter* user commands
│   ├── kernel.lua        # Kernel management (Phase 2)
│   ├── output.lua        # Output rendering: text, errors (Phase 2)
│   ├── image.lua         # image.nvim integration (Phase 3)
│   └── utils.lua         # Shared helpers
├── python/
│   └── kernel_bridge.py  # ZMQ ↔ JSON-line stdio daemon (Phase 2)
└── plugin/
    └── jupytervim.lua    # Auto-setup on VimEnter
```

### Data flow (Phase 2+)

```
User presses <leader>r
      │
      ▼
cell.lua       →  get_cell_source()  →  current buffer text
      │
      ▼
kernel.lua     →  jobstart JSON-line →  kernel_bridge.py
      │                                        │
      │                              jupyter_client (ZMQ)
      │                                        │
      │◄──── on_stdout JSON-line ──────────────┘
      │
output.lua     →  virt_lines        →  text / error inline
image.lua      →  image.nvim        →  kitty / ueberzugpp
```

---

## Development Roadmap

- **Phase 1** ✅ — Notebook parser, cell renderer, navigation, save
- **Phase 2** 🔜 — Kernel bridge, cell execution, inline output
- **Phase 3** 🔜 — Image rendering (Kitty protocol, ueberzugpp)
- **Phase 4** 🔜 — Markdown cell rendering, kernel completions, variable inspector

---

## Contributing

PRs and issues welcome at https://github.com/ansh-info/jupytervim.

---

## License

MIT — see [LICENSE](LICENSE).