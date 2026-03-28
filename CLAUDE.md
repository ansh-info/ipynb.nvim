# CLAUDE.md — jupytervim

Project-specific instructions for Claude Code. Read this before touching any file.

---

## What this project is

A Neovim plugin (`jupytervim`) that opens `.ipynb` Jupyter notebooks natively in
Neovim with Google Colab-style cell rendering, full Vim modal editing, Jupyter
kernel execution, and inline image/plot rendering via the Kitty graphics protocol.

---

## Repository layout

```
jupytervim/
├── lua/jupytervim/          # All Lua plugin code
│   ├── init.lua             # Entry point, setup(), autocmds
│   ├── config.lua           # Typed defaults + user deep-merge
│   ├── utils.lua            # Shared helpers (logging, file I/O, uid)
│   ├── notebook.lua         # .ipynb parse / serialise (nbformat 3 & 4)
│   ├── notebook_buf.lua     # Buffer lifecycle: open, save, sync, cleanup
│   ├── cell.lua             # Cell rendering (extmarks), navigation, mutation
│   ├── keymaps.lua          # Buffer-local keymaps + help overlay
│   ├── commands.lua         # :Jupyter* user commands
│   ├── kernel.lua           # Kernel management — Phase 2 (not yet written)
│   ├── output.lua           # Output rendering — Phase 2 (not yet written)
│   └── image.lua            # image.nvim integration — Phase 3 (not yet written)
├── python/                  # Python daemon (uv-managed project)
│   ├── pyproject.toml       # uv project config, Python 3.12
│   ├── uv.lock              # Reproducible lockfile — always commit this
│   └── kernel_bridge.py    # ZMQ <-> JSON-line stdio bridge (stub, Phase 2)
├── plugin/
│   └── jupytervim.lua       # Auto-setup shim loaded by Neovim on startup
├── CLAUDE.md                # This file
└── README.md                # User-facing docs (keep in sync with phases)
```

---

## Development phases

| Phase | Status | Scope |
|---|---|---|
| **1** | ✅ Done | Notebook parser, cell renderer, navigation, save |
| **2** | ✅ Done | kernel_bridge.py (ZMQ), kernel.lua, output.lua (inline text/error) |
| **3** | 🔜 Next | image.lua (Kitty protocol), image.nvim integration, plot rendering |
| **4** | Planned | Markdown cell rendering, kernel completions, variable inspector |

Always check this table before starting work. Never skip ahead — each phase
builds on the last.

---

## Python tooling — uv (mandatory)

This project uses **uv** for all Python dependency management. Never use pip directly.

```bash
# Install / sync dependencies (run from repo root)
uv sync --project python/

# Add a new dependency
uv add --project python/ <package>

# Run a script inside the venv
uv run --project python/ python python/kernel_bridge.py

# The venv lives at python/.venv/ — it is gitignored
```

The `pyproject.toml` lives at `python/pyproject.toml`. Python version is **3.12**.
After adding any dependency, always commit both `pyproject.toml` and `uv.lock`.

---

## Git workflow — mandatory rules

### One file per commit
Every commit must contain **exactly one file**. Never batch multiple files into
one commit.

```bash
# Correct
git add lua/jupytervim/kernel.lua
git commit -m "feat(lua): ..."

# Wrong — never do this
git add lua/jupytervim/kernel.lua lua/jupytervim/output.lua
git commit -m "..."
```

### No co-author lines
Never append `Co-Authored-By:` or any attribution trailer to commit messages.

### Conventional commits format
```
<type>(<scope>): <short description>

<optional body — what and why, not how>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`
Scopes: `lua`, `python`, `plugin`, `docs`, `config`

### Commit order for a new module
When adding a new module pair (e.g. `kernel.lua` + `kernel_bridge.py`):
1. Python file first
2. Lua file second
3. README/docs update last

---

## Architecture decisions (do not change without discussion)

### Cell rendering via extmarks only
Cell borders and output are rendered **exclusively** through `nvim_buf_set_extmark`
`virt_lines`. The buffer contains only raw source code. Never insert border
characters or output text as real buffer lines.

### JSON-line stdio daemon (not pynvim remote plugin)
`kernel_bridge.py` communicates with Neovim via newline-delimited JSON on
stdin/stdout, spawned via `vim.fn.jobstart()`. Do not convert this to a pynvim
remote plugin — the simpler stdio model is intentional.

### image.nvim as image backend (Phase 3)
Image rendering is delegated entirely to `image.nvim`. Do not implement raw
Kitty escape sequences directly in Lua — use image.nvim's API so ueberzugpp
and sixel users also benefit.

### Lazy-loaded kernel commands
All kernel-facing commands in `keymaps.lua` and `commands.lua` use `pcall(require,
"jupytervim.kernel")` so they fail gracefully in Phase 1 without erroring.
Keep this pattern when adding new phase-gated features.

---

## Key Neovim APIs used

```lua
-- Extmarks (cell borders + output)
vim.api.nvim_create_namespace("jupytervim_cells")
vim.api.nvim_buf_set_extmark(bufnr, ns, line, col, { virt_lines = ... })
vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, mark_id, {})
vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

-- Buffer interception
vim.api.nvim_create_autocmd("BufReadCmd",  { pattern = "*.ipynb", ... })
vim.api.nvim_create_autocmd("BufWriteCmd", { pattern = "*.ipynb", ... })

-- Async job (kernel bridge)
vim.fn.jobstart(cmd, { on_stdout = ..., on_stderr = ..., on_exit = ... })
vim.fn.chansend(job_id, json_line .. "\n")
```

---

## Testing a change locally

```bash
# Point Neovim at the local checkout (lazy.nvim dev mode)
# In your Neovim config:
#   { dir = "/home/oneai/jupytervim", ft = "ipynb" }

# Then open any notebook:
nvim /path/to/notebook.ipynb

# Check for Lua errors:
:messages
:checkhealth jupytervim   # (Phase 2+)
```

---

## What to do at the start of each session

1. Read this file.
2. Check `git log --oneline` to see where Phase work stopped.
3. Check `git status` — should be clean on `feat` branch.
4. Confirm which Phase is next from the table above.
5. Start with the Python file(s), then Lua, then docs.
