--- test/ansi_spec.lua
--- Tests for ipynb.ui.ansi: SGR escape parsing, 16/256/truecolor,
--- bold/italic/underline, highlight group caching, and edge cases.

describe("ipynb.ui.ansi", function()
  local ansi

  before_each(function()
    package.loaded["ipynb.ui.ansi"] = nil
    ansi = require("ipynb.ui.ansi")
    ansi.reset_highlights()
  end)

  local HL = "IpynbOutputText"

  -- ── has_ansi() ──────────────────────────────────────────────────────────────

  describe("has_ansi()", function()
    it("returns false for plain text", function()
      assert.is_false(ansi.has_ansi("hello world"))
    end)

    it("returns false for empty string", function()
      assert.is_false(ansi.has_ansi(""))
    end)

    it("returns true for text with SGR escape", function()
      assert.is_true(ansi.has_ansi("\27[31mred\27[0m"))
    end)

    it("returns true for text with cursor movement escape", function()
      assert.is_true(ansi.has_ansi("\27[2Amove up"))
    end)
  end)

  -- ── parse_line() basic ──────────────────────────────────────────────────────

  describe("parse_line()", function()
    it("returns single chunk for plain text", function()
      local result = ansi.parse_line("hello", HL)
      assert.are.equal(1, #result)
      assert.are.equal("hello", result[1][1])
      assert.are.equal(HL, result[1][2])
    end)

    it("returns default hl chunk for empty string", function()
      local result = ansi.parse_line("", HL)
      assert.are.equal(1, #result)
      assert.are.equal("", result[1][1])
    end)

    it("parses standard red foreground", function()
      local result = ansi.parse_line("\27[31mred text\27[0m", HL)
      local found = false
      for _, chunk in ipairs(result) do
        if chunk[1] == "red text" then
          found = true
          assert.are_not.equal(HL, chunk[2])
        end
      end
      assert.is_true(found, "expected a chunk with 'red text'")
    end)

    it("parses bold attribute", function()
      local result = ansi.parse_line("\27[1mbold\27[0m", HL)
      local found = false
      for _, chunk in ipairs(result) do
        if chunk[1] == "bold" then
          found = true
          assert.are_not.equal(HL, chunk[2])
        end
      end
      assert.is_true(found, "expected a chunk with 'bold'")
    end)

    it("parses italic attribute", function()
      local result = ansi.parse_line("\27[3mitalic\27[0m", HL)
      local found = false
      for _, chunk in ipairs(result) do
        if chunk[1] == "italic" then
          found = true
          assert.are_not.equal(HL, chunk[2])
        end
      end
      assert.is_true(found, "expected a chunk with 'italic'")
    end)

    it("parses underline attribute", function()
      local result = ansi.parse_line("\27[4munderlined\27[0m", HL)
      local found = false
      for _, chunk in ipairs(result) do
        if chunk[1] == "underlined" then
          found = true
          assert.are_not.equal(HL, chunk[2])
        end
      end
      assert.is_true(found, "expected a chunk with 'underlined'")
    end)

    it("parses combined bold and color", function()
      local result = ansi.parse_line("\27[1;31mbold red\27[0m", HL)
      local found = false
      for _, chunk in ipairs(result) do
        if chunk[1] == "bold red" then
          found = true
          assert.are_not.equal(HL, chunk[2])
        end
      end
      assert.is_true(found, "expected a chunk with 'bold red'")
    end)

    it("parses 256-color foreground", function()
      local result = ansi.parse_line("\27[38;5;208morange\27[0m", HL)
      local found = false
      for _, chunk in ipairs(result) do
        if chunk[1] == "orange" then
          found = true
          assert.are_not.equal(HL, chunk[2])
        end
      end
      assert.is_true(found, "expected a chunk with 'orange'")
    end)

    it("parses truecolor foreground", function()
      local result = ansi.parse_line("\27[38;2;255;128;0mtrue\27[0m", HL)
      local found = false
      for _, chunk in ipairs(result) do
        if chunk[1] == "true" then
          found = true
          assert.are_not.equal(HL, chunk[2])
        end
      end
      assert.is_true(found, "expected a chunk with 'true'")
    end)

    it("parses truecolor background", function()
      local result = ansi.parse_line("\27[48;2;255;128;0mbg\27[0m", HL)
      local found = false
      for _, chunk in ipairs(result) do
        if chunk[1] == "bg" then
          found = true
          assert.are_not.equal(HL, chunk[2])
        end
      end
      assert.is_true(found, "expected a chunk with 'bg'")
    end)

    it("parses 256-color background", function()
      local result = ansi.parse_line("\27[48;5;21mbg256\27[0m", HL)
      local found = false
      for _, chunk in ipairs(result) do
        if chunk[1] == "bg256" then
          found = true
          assert.are_not.equal(HL, chunk[2])
        end
      end
      assert.is_true(found, "expected a chunk with 'bg256'")
    end)

    it("handles reset via bare ESC[m", function()
      local result = ansi.parse_line("\27[31mred\27[mnormal", HL)
      local normal_found = false
      for _, chunk in ipairs(result) do
        if chunk[1] == "normal" then
          normal_found = true
          assert.are.equal(HL, chunk[2])
        end
      end
      assert.is_true(normal_found, "expected 'normal' to use default hl")
    end)

    it("handles explicit reset via ESC[0m", function()
      local result = ansi.parse_line("\27[31mred\27[0mnormal", HL)
      local normal_found = false
      for _, chunk in ipairs(result) do
        if chunk[1] == "normal" then
          normal_found = true
          assert.are.equal(HL, chunk[2])
        end
      end
      assert.is_true(normal_found, "expected 'normal' to use default hl after reset")
    end)
  end)

  -- ── Edge cases ──────────────────────────────────────────────────────────────

  describe("edge cases", function()
    it("handles ANSI at start of line", function()
      local result = ansi.parse_line("\27[31mstart", HL)
      assert.are.equal(1, #result)
      assert.are.equal("start", result[1][1])
    end)

    it("handles ANSI at end of line", function()
      local result = ansi.parse_line("end\27[31m", HL)
      assert.are.equal(1, #result)
      assert.are.equal("end", result[1][1])
    end)

    it("strips non-SGR CSI sequences (cursor movement)", function()
      local result = ansi.parse_line("before\27[2Aafter", HL)
      local texts = {}
      for _, chunk in ipairs(result) do
        texts[#texts + 1] = chunk[1]
      end
      local joined = table.concat(texts)
      assert.are.equal("beforeafter", joined)
    end)

    it("handles multiple resets in sequence", function()
      assert.has_no.errors(function()
        local result = ansi.parse_line("\27[0m\27[0m\27[0mtext", HL)
        assert.is_true(#result >= 1)
      end)
    end)

    it("handles bright/high-intensity foreground colors (90-97)", function()
      local result = ansi.parse_line("\27[91mbright red\27[0m", HL)
      local found = false
      for _, chunk in ipairs(result) do
        if chunk[1] == "bright red" then
          found = true
          assert.are_not.equal(HL, chunk[2])
        end
      end
      assert.is_true(found, "expected a chunk with 'bright red'")
    end)

    it("handles bright/high-intensity background colors (100-107)", function()
      local result = ansi.parse_line("\27[101mbright bg\27[0m", HL)
      local found = false
      for _, chunk in ipairs(result) do
        if chunk[1] == "bright bg" then
          found = true
          assert.are_not.equal(HL, chunk[2])
        end
      end
      assert.is_true(found, "expected a chunk with 'bright bg'")
    end)

    it("handles default fg reset (39)", function()
      local result = ansi.parse_line("\27[31mred\27[39mdefault", HL)
      local found = false
      for _, chunk in ipairs(result) do
        if chunk[1] == "default" then
          found = true
        end
      end
      assert.is_true(found)
    end)

    it("handles default bg reset (49)", function()
      local result = ansi.parse_line("\27[41mbg\27[49mno_bg", HL)
      local found = false
      for _, chunk in ipairs(result) do
        if chunk[1] == "no_bg" then
          found = true
        end
      end
      assert.is_true(found)
    end)

    it("handles attribute-specific resets (22, 23, 24)", function()
      local result = ansi.parse_line("\27[1;3;4mall\27[22;23;24mplain", HL)
      local found = false
      for _, chunk in ipairs(result) do
        if chunk[1] == "plain" then
          found = true
          assert.are.equal(HL, chunk[2])
        end
      end
      assert.is_true(found, "expected 'plain' to use default hl after attribute resets")
    end)
  end)

  -- ── Highlight group caching ─────────────────────────────────────────────────

  describe("highlight caching", function()
    it("reuses the same highlight group for identical styles", function()
      local r1 = ansi.parse_line("\27[31mfirst\27[0m", HL)
      local r2 = ansi.parse_line("\27[31msecond\27[0m", HL)
      local hl1, hl2
      for _, chunk in ipairs(r1) do
        if chunk[1] == "first" then
          hl1 = chunk[2]
        end
      end
      for _, chunk in ipairs(r2) do
        if chunk[1] == "second" then
          hl2 = chunk[2]
        end
      end
      assert.are.equal(hl1, hl2)
    end)

    it("uses different highlight groups for different styles", function()
      local r1 = ansi.parse_line("\27[31mred\27[0m", HL)
      local r2 = ansi.parse_line("\27[32mgreen\27[0m", HL)
      local hl1, hl2
      for _, chunk in ipairs(r1) do
        if chunk[1] == "red" then
          hl1 = chunk[2]
        end
      end
      for _, chunk in ipairs(r2) do
        if chunk[1] == "green" then
          hl2 = chunk[2]
        end
      end
      assert.are_not.equal(hl1, hl2)
    end)

    it("reset_highlights clears the cache", function()
      local r1 = ansi.parse_line("\27[31mfirst\27[0m", HL)
      local hl_before
      for _, chunk in ipairs(r1) do
        if chunk[1] == "first" then
          hl_before = chunk[2]
        end
      end

      ansi.reset_highlights()

      local r2 = ansi.parse_line("\27[31msecond\27[0m", HL)
      local hl_after
      for _, chunk in ipairs(r2) do
        if chunk[1] == "second" then
          hl_after = chunk[2]
        end
      end

      assert.are_not.equal(hl_before, hl_after)
    end)
  end)

  -- ── Line segmentation ──────────────────────────────────────────────────────

  describe("line segmentation", function()
    it("produces three segments for colored span between plain text", function()
      local result = ansi.parse_line("before\27[31mred\27[0mafter", HL)
      assert.are.equal(3, #result)
      assert.are.equal("before", result[1][1])
      assert.are.equal("red", result[2][1])
      assert.are.equal("after", result[3][1])
    end)

    it("preserves text content across multiple style changes", function()
      local result = ansi.parse_line("\27[31mr\27[32mg\27[34mb\27[0m", HL)
      local texts = {}
      for _, chunk in ipairs(result) do
        texts[#texts + 1] = chunk[1]
      end
      assert.are.equal("rgb", table.concat(texts))
    end)
  end)
end)
