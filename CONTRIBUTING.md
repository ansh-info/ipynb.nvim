# Contributing to ipynb.nvim

Thank you for your interest in contributing. This document covers everything
you need to get set up, run the test suite, and submit a pull request.

## Table of Contents

- [Development setup](#development-setup)
- [Running tests](#running-tests)
- [Code style](#code-style)
- [Project structure](#project-structure)
- [Submitting changes](#submitting-changes)
- [Reporting bugs](#reporting-bugs)

---

## Development setup

### Prerequisites

- Neovim >= 0.10.0
- Python >= 3.12
- [uv](https://github.com/astral-sh/uv)
- LuaRocks
- [stylua](https://github.com/JohnnyMorganz/StyLua) >= 0.20.0

### Install Python dependencies

```bash
uv sync --project python/
```

### Install Lua test dependencies (macOS)

```bash
brew install luarocks stylua
luarocks install vusted --local
luarocks install luacheck --local
export PATH="$HOME/.luarocks/bin:$PATH"
export VUSTED_USE_LOCAL=1
```

Add the two `export` lines to your shell profile so they persist across
sessions.

### Install Lua test dependencies (Linux)

```bash
sudo apt install luarocks
luarocks install vusted --local
luarocks install luacheck --local
export PATH="$HOME/.luarocks/bin:$PATH"
export VUSTED_USE_LOCAL=1

# stylua - download binary from GitHub releases
curl -L https://github.com/JohnnyMorganz/StyLua/releases/latest/download/stylua-linux-x86_64.zip \
  -o /tmp/stylua.zip && unzip /tmp/stylua.zip -d ~/.local/bin/
```

---

## Running tests

```bash
# Run the full CI gate (lint + format-check + test) - same as CI
make ci

# Individual targets
make test          # run busted spec files via vusted
make lint          # luacheck lua/ test/
make format-check  # stylua --check lua/ test/ (read-only, used in CI)
make format        # stylua lua/ test/ (writes in place)
```

CI runs automatically on every push and pull request via
`.github/workflows/ci.yml`.

### Writing new tests

- Place spec files in `test/` with a `_spec.lua` suffix.
- Reset `package.loaded` in `before_each` for test isolation.
- Stub heavy optional deps (kernel, image, markdown) via `package.preload`.
- Use `vim.fn.getcwd()` for any file path references - no hardcoded absolute
  paths.

Example stub pattern:

```lua
before_each(function()
  package.loaded["ipynb.kernel.output"] = nil
  package.preload["ipynb.core.cell"] = function()
    return { get_cells = function() return {} end }
  end
  output = require("ipynb.kernel.output")
end)
```

---

## Code style

- **Lua**: formatted with [stylua](https://github.com/JohnnyMorganz/StyLua)
  using the settings in `.stylua.toml` (2-space indent, 100-column width).
  Run `make format` before committing.
- **Lua lint**: checked with [luacheck](https://github.com/mpeterv/luacheck)
  using `.luacheckrc`. Run `make lint` to verify.
- **No em/en dashes**: use a regular hyphen `-` everywhere - in comments,
  docs, and commit messages.
- **Immutable patterns**: return new values rather than mutating in place.
- **Error handling**: use `pcall` for optional modules. Never silently swallow
  errors.

---

## Project structure

```
lua/ipynb/
├── init.lua              # Entry point
├── config.lua            # Defaults and user deep-merge
├── utils.lua             # Shared helpers
├── core/
│   ├── notebook.lua      # .ipynb parse/serialize
│   ├── notebook_buf.lua  # Buffer lifecycle
│   └── cell.lua          # Cell rendering and navigation
├── kernel/
│   ├── init.lua          # Kernel process and message routing
│   ├── output.lua        # Output renderer
│   └── completion.lua    # omnifunc + nvim-cmp source
└── ui/
    ├── image.lua         # snacks.nvim image rendering via Placement API
    ├── health.lua        # :checkhealth ipynb provider
    ├── markdown.lua      # Markdown cell decorator
    ├── inspector.lua     # Variable inspector
    ├── keymaps.lua       # Buffer-local keymaps
    └── commands.lua      # :Ipynb* user commands
python/
└── kernel_bridge.py      # ZMQ <-> JSON-line stdio daemon
test/
└── *_spec.lua            # busted spec files
```

For the full module path table and architecture decisions see
[CLAUDE.md](CLAUDE.md).

---

## Submitting changes

### Branch naming

```
feat/<short-description>     new feature
fix/<short-description>      bug fix
docs/<short-description>     documentation only
chore/<short-description>    tooling, config, CI
refactor/<short-description> code restructuring
```

### Commit rules

- **One file per commit** - no bundling multiple files into one commit.
- Follow [Conventional Commits](https://www.conventionalcommits.org/):
  `<type>(<scope>): <description>`
  - Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`
  - Scopes: `lua`, `python`, `plugin`, `docs`, `config`
- Run `make ci` and confirm it passes before opening a PR.

### Commit order when adding a feature

1. Python file (if any)
2. Lua file(s) - one commit per file
3. Test spec file(s) - one commit per file
4. README / CLAUDE.md last

### Pull request description

```
## Summary

- <bullet: what changed and why>

## Test plan

- [ ] <what to verify manually>
```

---

## Reporting bugs

Open an issue at https://github.com/ansh-info/ipynb.nvim/issues and use the
bug report template. Include:

- Neovim version (`nvim --version`)
- Plugin version (`:Lazy` or git SHA)
- Terminal and OS
- Minimal reproduction steps
- `:messages` output and any errors from `:IpynbKernelInfo`
