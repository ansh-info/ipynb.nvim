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
│   ├── health.lua            # :checkhealth ipynb provider
│   ├── core/
│   │   ├── notebook.lua      # .ipynb parse / serialise - nbformat 3 & 4
│   │   ├── notebook_buf.lua  # Buffer lifecycle: open, save, sync, cleanup hooks
│   │   └── cell.lua          # Cell rendering (extmarks), navigation, add/delete
│   ├── kernel/
│   │   ├── init.lua          # Spawns kernel_bridge.py, routes IOPub messages
│   │   ├── output.lua        # Output chunk -> virt_lines renderer + accumulator
│   │   └── completion.lua    # omnifunc + nvim-cmp async source
│   └── ui/
│       ├── ansi.lua          # SGR ANSI escape parser: 16/256/truecolor, bold/italic
│       ├── image.lua         # snacks.nvim image rendering: PNG/JPEG/SVG via Placement
│       ├── markdown.lua      # Markdown cell extmark decorator (concealing)
│       ├── inspector.lua     # Variable inspector floating window
│       ├── keymaps.lua       # Buffer-local keymaps + floating help overlay
│       └── commands.lua      # All :Ipynb* user commands
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
│   ├── test_notebook.ipynb   # Sample notebook fixture for tests
│   ├── config_spec.lua       # busted spec: ipynb.config
│   ├── utils_spec.lua        # busted spec: ipynb.utils
│   ├── notebook_spec.lua     # busted spec: ipynb.core.notebook
│   ├── cell_spec.lua         # busted spec: ipynb.core.cell
│   ├── output_spec.lua       # busted spec: ipynb.kernel.output
│   └── inspector_spec.lua    # busted spec: ipynb.ui.inspector
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md     # Bug report issue template
│   │   ├── feature_request.md # Feature request issue template
│   │   ├── other.md          # General issue template
│   │   └── config.yml        # Issue template chooser config
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
| `require("ipynb.ui.ansi")` | `lua/ipynb/ui/ansi.lua` |
| `require("ipynb.ui.image")` | `lua/ipynb/ui/image.lua` |
| `require("ipynb.ui.markdown")` | `lua/ipynb/ui/markdown.lua` |
| `require("ipynb.ui.inspector")` | `lua/ipynb/ui/inspector.lua` |
| `require("ipynb.ui.keymaps")` | `lua/ipynb/ui/keymaps.lua` |
| `require("ipynb.ui.commands")` | `lua/ipynb/ui/commands.lua` |
| `require("ipynb.health")` | `lua/ipynb/health.lua` |

`kernel/init.lua` is intentional - Lua resolves `require("ipynb.kernel")` to
`kernel/init.lua` automatically.

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

**Adding a new spec file:**
- Place it in `test/` with a `_spec.lua` suffix
- Reset `package.loaded` in `before_each` for test isolation
- Stub heavy deps (kernel, image, markdown) via `package.preload`
- Use `vim.fn.getcwd()` for any file paths (not hardcoded absolute paths)

---

## Python tooling - uv (for development)

Always use uv for development. There are **two separate uv projects** in this repo:

### `python/` - kernel bridge runtime deps

```bash
uv sync --project python/         # install / sync
uv lock --project python/         # regenerate lockfile after toml changes
uv add --project python/ <pkg>    # add a runtime dependency
```

### Root project - dev tooling (python-semantic-release)

```bash
uv sync          # install / sync (dev group always included)
uv lock          # regenerate lockfile after toml changes
uv add --dev <pkg>
```

### Rule: when pyproject.toml is modified

Always run the matching lock command first, then commit **both files separately**
(toml first, lockfile second).

---

## Writing style - mandatory rules

### No em or en dashes
Never use em dashes (--) or en dashes (-) anywhere - in docs, comments, or commit
messages. Use a regular hyphen (-) instead.

---

## Git workflow - mandatory rules

### One file per commit
Every commit must contain **exactly one file**. No exceptions.

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
architecture.

### snacks.nvim image rendering
All image rendering goes through `snacks.nvim` Placement API (`snacks.image.placement`).
Do not write raw Kitty escape sequences in Lua. Do not use image.nvim.
Placements use Kitty unicode placeholders embedded in virt_lines - they scroll
automatically with the buffer. No WinScrolled sync, no viewport guards, no
ImageMagick dependency. Support is detected via `terminal.env().placeholders`.

### pcall guard on optional modules
Modules that depend on optional features (kernel, image, markdown, nvim-cmp) are
always loaded via `pcall(require, "...")`.

### Notebook-level undo
Structural cell operations (add, delete, move, split, merge, duplicate, paste,
toggle type) are tracked by a notebook-level undo stack in `cell.lua`, not by
Neovim's buffer undo tree. All `render()` calls are undo-invisible
(`undolevels=-1`). Smart `u`/`<C-r>` keymaps in `notebook_buf.lua` route to
notebook undo when the native undo tree is at the render baseline, and to native
undo otherwise. Guards in `cell.lua` (`reanchor_end_marks`,
`snap_cursor_to_nearest`) still protect against stale extmarks.

---

## Namespaces in use

| Namespace | Owner | Purpose |
|---|---|---|
| `ipynb_cells` | `core/cell.lua` | Cell border + output extmarks |
| `ipynb_markdown` | `ui/markdown.lua` | Markdown decoration extmarks |
| `ipynb_inspector_hl` | `ui/inspector.lua` | Inspector window highlights |

---

## What to do at the start of each session

1. Read this file.
2. Run `git log --oneline` and `git status` - should be on `main`, clean.
3. All phases are complete - focus is on bug reports, tests, or polish.
4. If adding a new feature: Python first -> Lua (core/kernel/ui) -> test spec -> docs, one file per commit.
5. If fixing a bug: read the affected module, understand the design, minimal fix.
6. After any Lua change: run `make ci` locally or let CI verify on the PR.
7. Structural undo is handled by notebook-level undo stack (see Architecture
   decisions above). Native `u` handles in-cell text edits; notebook undo
   handles structural ops. Both are routed by smart keymaps in `notebook_buf.lua`.
