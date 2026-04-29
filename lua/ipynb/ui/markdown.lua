--- ipynb.ui.markdown
--- Lightweight inline renderer for markdown cells.
---
--- Applies extmark-based decorations (highlight groups + concealing) to
--- every markdown cell in the buffer after cell.render() is called.
--- Works entirely without external dependencies.
---
--- If render-markdown.nvim is installed it is used instead for richer output.
---
--- Decoration coverage:
---   H1–H4 headers     → bold, coloured, # concealed
---   Horizontal rules  → virtual overlay line
---   Blockquotes       → dimmed italic, > concealed
---   Bullet lists      → coloured bullet character
---   Ordered lists     → coloured number
---   Inline code       → highlighted span
---   Bold spans        → bold highlight
---   Italic spans      → italic highlight
---   Links             → underlined text, URL concealed
---   Cell background   → subtle background tint for the whole cell
---
--- Public API:
---   markdown.render(bufnr)   -- decorate all markdown cells
---   markdown.clear(bufnr)    -- remove all markdown decorations

local cell = require("ipynb.core.cell")

local M = {}
local NS = vim.api.nvim_create_namespace("ipynb_markdown")

-- ── Highlights ────────────────────────────────────────────────────────────────

local function define_highlights()
  vim.api.nvim_set_hl(0, "IpynbMdH1", { fg = "#ff9e64", bold = true, underline = true })
  vim.api.nvim_set_hl(0, "IpynbMdH2", { fg = "#e0af68", bold = true })
  vim.api.nvim_set_hl(0, "IpynbMdH3", { fg = "#9ece6a", bold = true })
  vim.api.nvim_set_hl(0, "IpynbMdH4", { fg = "#7dcfff" })
  vim.api.nvim_set_hl(0, "IpynbMdBold", { bold = true })
  vim.api.nvim_set_hl(0, "IpynbMdItalic", { italic = true })
  vim.api.nvim_set_hl(0, "IpynbMdCode", { fg = "#ff9e64", bg = "#252535" })
  vim.api.nvim_set_hl(0, "IpynbMdQuote", { fg = "#565f89", italic = true })
  vim.api.nvim_set_hl(0, "IpynbMdBullet", { fg = "#7aa2f7", bold = true })
  vim.api.nvim_set_hl(0, "IpynbMdRule", { fg = "#3b4261" })
  vim.api.nvim_set_hl(0, "IpynbMdLink", { fg = "#7aa2f7", underline = true })
  vim.api.nvim_set_hl(0, "IpynbMdCellBg", { bg = "#1a1b2e" })
end

-- ── Per-line decorator ────────────────────────────────────────────────────────

--- Apply extmark decorations to a single line of markdown content.
---@param bufnr integer
---@param row integer  0-based line number
---@param line string  raw line text
local function decorate_line(bufnr, row, line)
  -- ── Headers ────────────────────────────────────────────────────────────────
  local hashes, _ = line:match("^(#{1,6})%s+(.*)")
  if hashes then
    local level = math.min(#hashes, 4)
    -- Highlight the whole line.
    vim.api.nvim_buf_set_extmark(bufnr, NS, row, 0, {
      end_col = #line,
      hl_group = "IpynbMdH" .. level,
      priority = 60,
    })
    -- Conceal the leading "# " prefix.
    vim.api.nvim_buf_set_extmark(bufnr, NS, row, 0, {
      end_col = #hashes + 1,
      conceal = "",
      priority = 70,
    })
    return -- headers don't also get inline processing
  end

  -- ── Horizontal rule ────────────────────────────────────────────────────────
  if line:match("^%-%-%-+%s*$") or line:match("^%*%*%*+%s*$") or line:match("^___%s*$") then
    vim.api.nvim_buf_set_extmark(bufnr, NS, row, 0, {
      virt_text = { { string.rep("─", 60), "IpynbMdRule" } },
      virt_text_pos = "overlay",
      priority = 70,
    })
    return
  end

  -- ── Blockquote ─────────────────────────────────────────────────────────────
  if line:match("^>") then
    vim.api.nvim_buf_set_extmark(bufnr, NS, row, 0, {
      end_col = #line,
      hl_group = "IpynbMdQuote",
      priority = 60,
    })
    -- Conceal ">" marker + optional space.
    local prefix = line:match("^(>%s?)")
    if prefix then
      vim.api.nvim_buf_set_extmark(bufnr, NS, row, 0, {
        end_col = #prefix,
        conceal = "┃",
        priority = 70,
      })
    end
    return
  end

  -- ── Unordered list ─────────────────────────────────────────────────────────
  local indent, bullet_char = line:match("^(%s*)([-*+])%s")
  if indent and bullet_char then
    vim.api.nvim_buf_set_extmark(bufnr, NS, row, #indent, {
      end_col = #indent + 1,
      hl_group = "IpynbMdBullet",
      virt_text = { { "●", "IpynbMdBullet" } },
      virt_text_pos = "overlay",
      priority = 70,
    })
  end

  -- ── Ordered list ───────────────────────────────────────────────────────────
  local num_prefix = line:match("^%s*%d+%.")
  if num_prefix then
    vim.api.nvim_buf_set_extmark(bufnr, NS, row, 0, {
      end_col = #num_prefix,
      hl_group = "IpynbMdBullet",
      priority = 60,
    })
  end

  -- ── Inline code ────────────────────────────────────────────────────────────
  -- Scan for `...` spans.
  local col = 0
  local search = line
  while true do
    local s, e = search:find("`([^`]+)`")
    if not s then
      break
    end
    local abs_s = col + s - 1
    local abs_e = col + e - 1
    vim.api.nvim_buf_set_extmark(bufnr, NS, row, abs_s, {
      end_col = abs_e + 1,
      hl_group = "IpynbMdCode",
      priority = 65,
    })
    -- Conceal backtick delimiters.
    vim.api.nvim_buf_set_extmark(bufnr, NS, row, abs_s, {
      end_col = abs_s + 1,
      conceal = "",
      priority = 75,
    })
    vim.api.nvim_buf_set_extmark(bufnr, NS, row, abs_e, {
      end_col = abs_e + 1,
      conceal = "",
      priority = 75,
    })
    col = col + e
    search = search:sub(e + 1)
  end

  -- ── Bold **text** ──────────────────────────────────────────────────────────
  col = 0
  search = line
  while true do
    local s, e = search:find("%*%*([^%*]+)%*%*")
    if not s then
      break
    end
    local abs_s = col + s - 1
    local abs_e = col + e - 1
    vim.api.nvim_buf_set_extmark(bufnr, NS, row, abs_s + 2, {
      end_col = abs_e - 1,
      hl_group = "IpynbMdBold",
      priority = 65,
    })
    -- Conceal ** delimiters.
    vim.api.nvim_buf_set_extmark(
      bufnr,
      NS,
      row,
      abs_s,
      { end_col = abs_s + 2, conceal = "", priority = 75 }
    )
    vim.api.nvim_buf_set_extmark(
      bufnr,
      NS,
      row,
      abs_e - 1,
      { end_col = abs_e + 1, conceal = "", priority = 75 }
    )
    col = col + e
    search = search:sub(e + 1)
  end

  -- ── Italic *text* (single asterisk, not part of **) ───────────────────────
  col = 0
  search = line
  while true do
    local s, e = search:find("%f[%*]%*([^%*]+)%*%f[^%*]")
    if not s then
      break
    end
    local abs_s = col + s - 1
    local abs_e = col + e - 1
    vim.api.nvim_buf_set_extmark(bufnr, NS, row, abs_s + 1, {
      end_col = abs_e,
      hl_group = "IpynbMdItalic",
      priority = 65,
    })
    vim.api.nvim_buf_set_extmark(
      bufnr,
      NS,
      row,
      abs_s,
      { end_col = abs_s + 1, conceal = "", priority = 75 }
    )
    vim.api.nvim_buf_set_extmark(
      bufnr,
      NS,
      row,
      abs_e,
      { end_col = abs_e + 1, conceal = "", priority = 75 }
    )
    col = col + e
    search = search:sub(e + 1)
  end

  -- ── Markdown links [text](url) ─────────────────────────────────────────────
  col = 0
  search = line
  while true do
    local s, link_text, url_s, url_e, e = search:find("%[([^%]]+)%]()%(([^%)]+)%)()")
    if not s then
      break
    end
    local abs_s = col + s - 1
    local abs_url_s = col + url_s - 1
    local abs_url_e = col + url_e - 2

    -- Highlight the link text.
    vim.api.nvim_buf_set_extmark(bufnr, NS, row, abs_s + 1, {
      end_col = abs_s + 1 + #link_text,
      hl_group = "IpynbMdLink",
      priority = 65,
    })
    -- Conceal "[", "]", "(" ... ")" leaving only the link text visible.
    vim.api.nvim_buf_set_extmark(
      bufnr,
      NS,
      row,
      abs_s,
      { end_col = abs_s + 1, conceal = "", priority = 75 }
    )
    vim.api.nvim_buf_set_extmark(
      bufnr,
      NS,
      row,
      abs_url_s - 2,
      { end_col = abs_url_s - 1, conceal = "", priority = 75 }
    )
    vim.api.nvim_buf_set_extmark(
      bufnr,
      NS,
      row,
      abs_url_s - 1,
      { end_col = abs_url_e + 1, conceal = "", priority = 75 }
    )

    col = col + e - 1
    search = search:sub(e)
  end
end

-- ── Cell-level renderer ───────────────────────────────────────────────────────

--- Decorate all markdown cells in a buffer.
---@param bufnr integer
function M.render(bufnr)
  define_highlights()
  vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)

  -- render-markdown.nvim integration removed: it applies decorations to the
  -- entire buffer (including code cells) because it expects a pure markdown
  -- filetype. The built-in decorator below is cell-aware.

  local ns = cell.namespace()
  local cells = cell.get_cells(bufnr)

  -- Collect code cell ranges for treesitter region restriction (see below).
  local code_regions = {}

  for _, cs in ipairs(cells) do
    -- Get line range from extmarks.
    local sm = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, cs.start_mark, {})
    local em = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, cs.end_mark, {})
    local start_row = sm[1] or 0
    local end_row = em[1] or start_row

    if cs.cell_type == "code" then
      -- Range4: {start_row, start_col, end_row, end_col} (0-indexed).
      code_regions[#code_regions + 1] = { start_row, 0, end_row, 0 }
    else
      -- Subtle background tint for the whole markdown cell.
      vim.api.nvim_buf_set_extmark(bufnr, NS, start_row, 0, {
        end_row = end_row + 1,
        end_col = 0,
        hl_group = "IpynbMdCellBg",
        hl_eol = true,
        priority = 50,
      })

      -- Decorate each line.
      local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
      for i, line in ipairs(lines) do
        decorate_line(bufnr, start_row + i - 1, line)
      end
    end
  end

  -- Restrict the Python treesitter parser to code cell ranges so that markdown
  -- prose is not highlighted with Python syntax colors.
  -- set_included_regions is available since Neovim 0.9; guard with pcall.
  local ok_p, parser = pcall(vim.treesitter.get_parser, bufnr, "python")
  if ok_p and parser and parser.set_included_regions then
    pcall(function()
      -- Passing an empty outer list resets to "parse whole buffer"; pass a
      -- non-empty list only when there are code cells to restrict to.
      if #code_regions > 0 then
        parser:set_included_regions({ code_regions })
      else
        parser:set_included_regions({})
      end
    end)
  end
end

--- Remove all markdown decorations from a buffer.
---@param bufnr integer
function M.clear(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)
end

M.define_highlights = define_highlights

return M
