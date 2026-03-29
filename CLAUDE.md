# CLAUDE.md - ipynb

Project-specific instructions for Claude Code. Read this before touching any file.

---

## What this project is

A Neovim plugin (`ipynb`) that opens `.ipynb` Jupyter notebooks natively in
Neovim with Google Colab-style cell rendering, full Vim modal editing, Jupyter
kernel execution via ZMQ, inline text/image output, and a variable inspector.

**All development phases are complete.** Future work is bug-fixing, testing,
and polish - not new phases.

---

## Repository layout

```
ipynb/
├── lua/ipynb/
│   ├── init.lua              # Entry point: setup(), BufReadCmd/BufWriteCmd autocmds
│   ├── config.lua            # Typed defaults + user deep-merge (IpynbConfig)
│   ├── utils.lua             # log/warn/err, read_file/write_file, uid, has_plugin
│   ├── core/
│   │   ├── notebook.lua      # .ipynb parse / serialise - nbformat 3 & 4
│   │   ├── notebook_buf.lua  # Buffer lifecycle: open, save, sync, cleanup hooks
│   │   └── cell.lua          # Cell rendering (extmarks), navigation, add/delete
│   ├── kernel/
│   │   ├── init.lua          # Spawns kernel_bridge.py, routes IOPub messages
│   │   ├── output.lua        # Output chunk -> virt_lines renderer + accumulator
│   │   └── completion.lua    # omnifunc + nvim-cmp async source
│   └── ui/
│       ├── image.lua         # image.nvim integration: PNG/JPEG/SVG rendering
│       ├── markdown.lua      # Markdown cell extmark decorator (concealing)
│       ├── inspector.lua     # Variable inspector floating window
│       ├── keymaps.lua       # Buffer-local keymaps + floating help overlay
│       └── commands.lua      # All :Jupyter* user commands
├── python/
│   ├── pyproject.toml        # uv project, Python >=3.12 - runtime deps
│   ├── uv.lock               # Reproducible lockfile - always commit alongside toml
│   └── kernel_bridge.py      # Full ZMQ <-> JSON-line stdio daemon
├── plugin/
│   └── ipynb.lua             # Auto-setup shim (sets guard flag)
├── ftdetect/
│   └── ipynb.vim             # Sets filetype=ipynb for *.ipynb files
├── test/
│   ├── minimal_init.lua      # Minimal Neovim init for vusted test runner
│   ├── headless_test.lua     # Headless integration checks (module loading, statics)
│   ├── config_spec.lua       # busted spec: ipynb.config
│   ├── utils_spec.lua        # busted spec: ipynb.utils
│   ├── notebook_spec.lua     # busted spec: ipynb.core.notebook
│   ├── cell_spec.lua         # busted spec: ipynb.core.cell
│   ├── output_spec.lua       # busted spec: ipynb.kernel.output
│   └── inspector_spec.lua    # busted spec: ipynb.ui.inspector
├── .github/
│   └── workflows/
│       ├── ci.yml            # test + lint + format-check on every push/PR
│       └── release.yml       # python-semantic-release on push to main
├── .luacheckrc               # luacheck config (globals, max_line_length, ignores)
├── .stylua.toml              # stylua config (2-space indent, 100 col width)
├── Makefile                  # make test / lint / format / format-check / ci
├── pyproject.toml            # Root: semantic release config + dev deps
├── uv.lock                   # Root lockfile for semantic release
├── CLAUDE.md                 # This file
└── README.md                 # User-facing install and usage docs
```

---

## Module paths

After the Phase 3 folder restructuring, the Lua module paths are:

| Module | Path |
|---|---|
| `require("ipynb")` | `lua/ipynb/init.lua` |
| `require("ipynb.config")` | `lua/ipynb/config.lua` |
| `require("ipynb.utils")` | `lua/ipynb/utils.lua` |
| `require("ipynb.core.notebook")` | `lua/ipynb/core/notebook.lua` |
| `require("ipynb.core.notebook_buf")` | `lua/ipynb/core/notebook_buf.lua` |
| `require("ipynb.core.cell")` | `lua/ipynb/core/cell.lua` |
| `require("ipynb.kernel")` | `lua/ipynb/kernel/init.lua` |
| `require("ipynb.kernel.output")` | `lua/ipynb/kernel/output.lua` |
| `require("ipynb.kernel.completion")` | `lua/ipynb/kernel/completion.lua` |
| `require("ipynb.ui.image")` | `lua/ipynb/ui/image.lua` |
| `require("ipynb.ui.markdown")` | `lua/ipynb/ui/markdown.lua` |
| `require("ipynb.ui.inspector")` | `lua/ipynb/ui/inspector.lua` |
| `require("ipynb.ui.keymaps")` | `lua/ipynb/ui/keymaps.lua` |
| `require("ipynb.ui.commands")` | `lua/ipynb/ui/commands.lua` |

`kernel/init.lua` is intentional - Lua resolves `require("ipynb.kernel")` to
`kernel/init.lua` automatically, so all call sites are unchanged.

---

## Development phases - all complete

| Phase | Status | Scope |
|---|---|---|
| **1** | Done | core/notebook.lua, core/notebook_buf.lua, core/cell.lua, ui/keymaps.lua, ui/commands.lua |
| **2** | Done | kernel_bridge.py (full ZMQ), kernel/init.lua, kernel/output.lua |
| **3** | Done | ui/image.lua (PNG/JPEG/SVG via image.nvim, base64 decode) |
| **4** | Done | ui/markdown.lua, kernel/completion.lua, ui/inspector.lua |
| **Tooling** | Done | .luacheckrc, .stylua.toml, Makefile, test suite, GitHub Actions CI |
| **Refactor** | Done | Folder restructure into core/, kernel/, ui/ |

---

## Testing

The test suite uses [busted](https://lunarmodules.github.io/busted/) via
[vusted](https://github.com/notomo/vusted) (busted inside headless Neovim).

```bash
# Run full CI gate (lint + format-check + test)
make ci

# Individual targets
make test          # run busted spec files via vusted
make lint          # luacheck lua/ test/
make format        # stylua lua/ test/ (writes in place)
make format-check  # stylua --check lua/ test/ (used in CI)
```

**Install test dependencies (once):**
```bash
# macOS
brew install luarocks stylua
luarocks install vusted --local
luarocks install luacheck --local
export PATH="$HOME/.luarocks/bin:$PATH"
export VUSTED_USE_LOCAL=1
```

**CI** runs automatically on every push and PR via `.github/workflows/ci.yml`:
- `test` job: installs LuaJIT + LuaRocks + Neovim stable + vusted, runs `make test`
- `lint` job: luacheck via `lunarmodules/luacheck` Docker action
- `format` job: stylua `--check` via `JohnnyMorganz/stylua-action`

**Adding a new spec file:**
- Place it in `test/` with a `_spec.lua` suffix
- Reset `package.loaded` in `before_each` for test isolation
- Stub heavy deps (kernel, image, markdown) via `package.preload`
- Use `vim.fn.getcwd()` for any file paths (not hardcoded absolute paths)

---

## Python tooling - uv (for development)

Always use uv for development. The end-user build hook falls back to
`python3 -m venv` when uv is absent - but never use that fallback yourself.

There are **two separate uv projects** in this repo:

### `python/` - kernel bridge runtime deps

`python/pyproject.toml` declares the runtime deps (`ipykernel`, `jupyter-client`,
`nbformat`). The venv lives at `python/.venv/` (gitignored).

```bash
# Install / sync after python/pyproject.toml or python/uv.lock changes
uv sync --project python/

# Regenerate python/uv.lock after editing python/pyproject.toml
uv lock --project python/

# Add a new runtime dependency
uv add --project python/ <package>

# Run a script inside the venv without activating it
uv run --project python/ python python/kernel_bridge.py
```

### Root project - dev tooling (python-semantic-release)

Root `pyproject.toml` uses `[dependency-groups]` with a `dev` group for
`python-semantic-release`. The `dev` group is included by default on every
`uv sync` - there is **no `--dev` flag** in uv (unlike Poetry/pip).

```bash
# Install / sync after pyproject.toml or uv.lock changes
# dev group is always included by default
uv sync

# Regenerate root uv.lock after editing root pyproject.toml
uv lock

# Add a package to the dev group
uv add --dev <package>

# Sync without dev group (for validation only - not for normal dev)
uv sync --no-dev
```

### Rule: when pyproject.toml is modified

Always run the matching lock command first, then commit **both files separately**
(toml first, lockfile second):

```bash
# python/pyproject.toml changed
uv lock --project python/
git add python/pyproject.toml && git commit -m "..."
git add python/uv.lock       && git commit -m "..."

# root pyproject.toml changed
uv lock
git add pyproject.toml && git commit -m "..."
git add uv.lock        && git commit -m "..."
```

---

## Writing style - mandatory rules

### No em or en dashes
Never use em dashes (--) or en dashes (-) anywhere - in docs, comments, or commit
messages. Use a regular hyphen (-) instead.

---

## Git workflow - mandatory rules

### One file per commit
Every commit must contain **exactly one file**. No exceptions.

```bash
# Correct
git add lua/ipynb/core/cell.lua
git commit -m "feat(lua): ..."

# Wrong
git add lua/ python/
git commit -m "..."
```

### Co-author
Always add these trailers to every commit, in this order:
```
Co-authored-by: Ansh Kumar <anshkumar.info@gmail.com>
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
3. Test spec file(s)
4. README / CLAUDE.md last

### Branch naming
```
feat/<short-description>     new feature
fix/<short-description>      bug fix or cleanup
docs/<short-description>     documentation only
chore/<short-description>    tooling, config, CI
refactor/<short-description> code restructuring
```

### Pull request description
Every PR must follow this structure:

```
## Summary

- <bullet: what changed and why>
- <bullet: ...>

## Test plan

- [ ] <what to verify manually>
- [ ] <...>
```

- No "Generated with Claude Code" or AI attribution
- Title follows conventional commit format: `feat: ...` / `fix: ...`
- Keep title under 72 characters

---

## Architecture decisions - do not change without discussion

### Extmark-only rendering
All cell borders, status indicators, and output blocks are rendered via
`nvim_buf_set_extmark` `virt_lines`. The buffer contains **only raw source code**.
Never insert decorations or output as real buffer lines.

### JSON-line stdio daemon (not pynvim)
`kernel_bridge.py` is spawned by `vim.fn.jobstart()` and communicates via
newline-delimited JSON on stdin/stdout. Do not switch to pynvim remote plugin
architecture - the stdio model is simpler and avoids registration overhead.

### ZMQ -> Lua msg_id translation in the bridge
`kernel_bridge.py` maintains a `_pending` dict mapping ZMQ msg_ids -> Lua msg_ids
internally. All messages emitted to stdout carry the original Lua `msg_id` so
`kernel/init.lua` never needs to know about ZMQ ids.

### image.nvim delegation
All image rendering goes through `image.nvim`. Do not write raw Kitty escape
sequences in Lua - `image.nvim` handles Kitty / ueberzugpp / sixel backends
transparently.

### pcall guard on optional modules
Modules that depend on optional features (kernel, image, markdown, nvim-cmp) are
always loaded via `pcall(require, "...")`. This ensures the plugin never errors if
optional dependencies are absent.

### Re-entrancy guard in kernel/output.lua
`image.nvim`'s `magick_cli` processor uses `vim.wait()` which runs the Neovim
event loop mid-render. The `_active`/`_pending` guard in `kernel/output.lua`
prevents a second `output.append()` from calling `image.clear()` while the first
magick process is still reading the temp PNG file.

---

## Namespaces in use

| Namespace | Owner | Purpose |
|---|---|---|
| `ipynb_cells` | `core/cell.lua` | Cell border + output extmarks |
| `ipynb_markdown` | `ui/markdown.lua` | Markdown decoration extmarks |
| `ipynb_inspector_hl` | `ui/inspector.lua` | Inspector window highlights |

---

## Key Neovim APIs

```lua
-- Extmarks
vim.api.nvim_create_namespace("ipynb_cells")
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

-- Blocking wait (used in kernel/completion.lua omnifunc)
vim.wait(timeout_ms, predicate, interval_ms)
```

---

## What to do at the start of each session

1. Read this file.
2. Run `git log --oneline` and `git status` - should be on `main`, clean.
3. All phases are complete - focus is on bug reports, tests, or polish.
4. If adding a new feature: Python first -> Lua (core/kernel/ui as appropriate) -> test spec -> docs, one file per commit.
5. If fixing a bug: read the affected module, understand the design, minimal fix.
6. After any Lua change: run `make ci` locally or let CI verify on the PR.
