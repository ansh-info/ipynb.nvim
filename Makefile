# ipynb.nvim - development convenience targets
#
# Prerequisites (install once):
#   luarocks install vusted      # test runner (runs busted inside Neovim)
#   luarocks install luacheck    # static analysis
#   cargo install stylua         # or: brew install stylua / apt install stylua
#
# Usage:
#   make test          run the full test suite
#   make lint          run luacheck static analysis
#   make format        auto-format all Lua files (writes in place)
#   make format-check  check formatting without writing (used in CI)
#   make ci            lint + format-check + test (full CI gate)

.PHONY: test lint format format-check ci

NVIM       ?= nvim
VUSTED     ?= vusted
LUACHECK   ?= luacheck
STYLUA     ?= stylua

# ── Test ──────────────────────────────────────────────────────────────────────

test:
	$(VUSTED) --output=utfTerminal test/

# ── Lint ──────────────────────────────────────────────────────────────────────

lint:
	$(LUACHECK) lua/ test/

# ── Format ────────────────────────────────────────────────────────────────────

format:
	$(STYLUA) lua/ test/

format-check:
	$(STYLUA) --check lua/ test/

# ── CI gate ───────────────────────────────────────────────────────────────────

ci: lint format-check test
