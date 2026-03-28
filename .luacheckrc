-- luacheck configuration for ipynb.nvim
-- Run: luacheck lua/ test/

-- Neovim injects `vim` as a global.
globals = { "vim" }

-- busted test globals (describe, it, before_each, etc.)
read_globals = {
  "describe",
  "it",
  "before_each",
  "after_each",
  "after_each",
  "pending",
  "spy",
  "stub",
  "mock",
  "assert",
  "insulate",
  "expose",
}

max_line_length = 120

-- 212: unused argument    - common in Neovim event callbacks (bufnr, event, ...)
-- 213: unused loop variable - common in ipairs/pairs iterations
ignore = { "212", "213" }

exclude_files = {
  "python/.venv/",
  ".venv/",
}
