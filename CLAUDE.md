# CLAUDE.md — jupytervim

Project-specific instructions for Claude Code. Read this before touching any file.

---

## What this project is

A Neovim plugin (`jupytervim`) that opens `.ipynb` Jupyter notebooks natively in
Neovim with Google Colab-style cell rendering, full Vim modal editing, Jupyter
kernel execution via ZMQ, inline text/image output, and a variable inspector.

**All four development phases are complete.** Future work is bug-fixing, testing,
and polish — not new phases.

---

## Repository layout

```
jupytervim/
├── lua/jupytervim/
│   ├── init.lua          # Entry point: setup(), BufReadCmd/BufWriteCmd autocmds
│   ├── config.lua        # Typed defaults + user deep-merge (JupytervimConfig)
│   ├── utils.lua         # log/warn/err, read_file/write_file, uid, has_plugin
│   ├── notebook.lua      # .ipynb parse / serialise — nbformat 3 & 4
│   ├── notebook_buf.lua  # Buffer lifecycle: open, save, sync, cleanup hooks
│   ├── cell.lua          # Cell rendering (extmarks), navigation, add/delete
│   ├── keymaps.lua       # Buffer-local keymaps + floating help overlay
│   ├── commands.lua      # All :Jupyter* user commands
│   ├── kernel.lua        # Spawns kernel_bridge.py, routes IOPub messages
│   ├── output.lua        # Output chunk → virt_lines renderer + accumulator
│   ├── image.lua         # image.nvim integration: PNG/JPEG/SVG rendering
│   ├── markdown.lua      # Markdown cell extmark decorator (concealing)
│   ├── completion.lua    # omnifunc + nvim-cmp async source
│   └── inspector.lua     # Variable inspector floating window
├── python/
│   ├── pyproject.toml    # uv project, Python >=3.12
│   ├── uv.lock           # Reproducible lockfile — always commit alongside toml
│   └── kernel_bridge.py  # Full ZMQ ↔ JSON-line stdio daemon
├── plugin/
│   └── jupytervim.lua    # Auto-setup shim on VimEnter
├── CLAUDE.md             # This file
└── README.md             # User-facing docs with Mermaid diagrams
```

---

## Development phases — all complete

| Phase | Status | Scope |
|---|---|---|
| **1** | ✅ Done | notebook.lua, notebook_buf.lua, cell.lua, keymaps.lua, commands.lua |
| **2** | ✅ Done | kernel_bridge.py (full ZMQ), kernel.lua, output.lua |
| **3** | ✅ Done | image.lua (PNG/JPEG/SVG via image.nvim, base64 decode) |
| **4** | ✅ Done | markdown.lua, completion.lua, inspector.lua |

---

## Python tooling — uv (mandatory)

**Never use pip directly.** Always use uv.

```bash
# Sync / install all dependencies (run from repo root)
uv sync --project python/

# Add a new runtime dependency
uv add --project python/ <package>

# Add a dev-only dependency
uv add --project python/ --dev <package>

# Run a script inside the venv without activating it
uv run --project python/ python python/kernel_bridge.py

# The venv lives at python/.venv/ — it is gitignored
```

`pyproject.toml` is at `python/pyproject.toml`. Python version pin: **>=3.12**.
After `uv add`, always commit both `python/pyproject.toml` and `python/uv.lock`
as **separate commits** (toml first, then lockfile).

---

## Git workflow — mandatory rules

### One file per commit
Every commit must contain **exactly one file**. No exceptions.

```bash
# Correct
git add lua/jupytervim/kernel.lua
git commit -m "feat(lua): ..."

# Wrong
git add lua/ python/
git commit -m "..."
```

### Co-author
Always add this trailer to every commit:
```
Co-authored-by: Apoorva Gupta <apoorvaagupta.info@gmail.com>
```
Do **not** add any Claude Code or AI attribution.

### Conventional commits
```
<type>(<scope>): <description>

<optional body>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`
Scopes: `lua`, `python`, `plugin`, `docs`, `config`

### Commit order when adding a feature
1. Python file (if any)
2. Lua file(s) one at a time
3. README / CLAUDE.md last

---

## Architecture decisions — do not change without discussion

### Extmark-only rendering
All cell borders, status indicators, and output blocks are rendered via
`nvim_buf_set_extmark` `virt_lines`. The buffer contains **only raw source code**.
Never insert decorations or output as real buffer lines.

### JSON-line stdio daemon (not pynvim)
`kernel_bridge.py` is spawned by `vim.fn.jobstart()` and communicates via
newline-delimited JSON on stdin/stdout. Do not switch to pynvim remote plugin
architecture — the stdio model is simpler and avoids registration overhead.

### ZMQ → Lua msg_id translation in the bridge
`kernel_bridge.py` maintains a `_pending` dict mapping ZMQ msg_ids → Lua msg_ids
internally. All messages emitted to stdout carry the original Lua `msg_id` so
`kernel.lua` never needs to know about ZMQ ids.

### image.nvim delegation
All image rendering goes through `image.nvim`. Do not write raw Kitty escape
sequences in Lua — `image.nvim` handles Kitty / ueberzugpp / sixel backends
transparently.

### pcall guard on phase-gated modules
Modules that depend on later phases (kernel, image) are always loaded via
`pcall(require, "...")`. This ensures the plugin never errors if a phase's code
is missing or if optional dependencies (image.nvim, nvim-cmp) are absent.

---

## Namespaces in use

| Namespace | Owner | Purpose |
|---|---|---|
| `jupytervim_cells` | `cell.lua` | Cell border + output extmarks |
| `jupytervim_markdown` | `markdown.lua` | Markdown decoration extmarks |
| `jupyvim_inspector_hl` | `inspector.lua` | Inspector window highlights |

---

## Key Neovim APIs

```lua
-- Extmarks
vim.api.nvim_create_namespace("jupytervim_cells")
vim.api.nvim_buf_set_extmark(bufnr, ns, line, col, { virt_lines = {...} })
vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, mark_id, {})
vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

-- Buffer interception
vim.api.nvim_create_autocmd("BufReadCmd",  { pattern = "*.ipynb" })
vim.api.nvim_create_autocmd("BufWriteCmd", { pattern = "*.ipynb" })

-- Async job
vim.fn.jobstart(cmd, { on_stdout, on_stderr, on_exit,
                       stdout_buffered = false })
vim.fn.chansend(job_id, json_line .. "\n")

-- Blocking wait (used in completion.omnifunc)
vim.wait(timeout_ms, predicate, interval_ms)
```

---

## Testing locally

```bash
# lazy.nvim dev mode — add to your Neovim config:
{ dir = "/home/oneai/jupytervim", ft = "ipynb" }

# Open a notebook
nvim /path/to/notebook.ipynb

# Check for Lua errors
:messages

# Verify the kernel bridge Python
uv run --project python/ python python/kernel_bridge.py
# Type: {"cmd":"start","kernel":"python3"}
# Expected: {"type":"status","state":"starting",...}
```

---

## What to do at the start of each session

1. Read this file.
2. Run `git log --oneline` and `git status` — branch should be `feat`, clean.
3. All phases are complete — focus is on bug reports, tests, or polish.
4. If adding a new feature: Python first → Lua → docs, one file per commit.
5. If fixing a bug: read the affected module, understand the design, minimal fix.
