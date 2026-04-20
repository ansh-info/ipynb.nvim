--- test/utils_spec.lua
--- Tests for ipynb.utils: pure-Lua helpers that do not require a real Neovim session.

describe("ipynb.utils", function()
  local utils

  before_each(function()
    package.loaded["ipynb.utils"] = nil
    utils = require("ipynb.utils")
  end)

  -- ── M.read_file() / M.write_file() ───────────────────────────────────────────

  describe("M.read_file() / M.write_file()", function()
    it("round-trips a plain text string", function()
      local tmp = os.tmpname()
      local ok, err = utils.write_file(tmp, "hello world")
      assert.is_true(ok)
      assert.is_nil(err)

      local content, rerr = utils.read_file(tmp)
      assert.are.equal("hello world", content)
      assert.is_nil(rerr)
      os.remove(tmp)
    end)

    it("round-trips a multi-line string", function()
      local tmp = os.tmpname()
      local data = "line1\nline2\nline3\n"
      utils.write_file(tmp, data)
      local got = utils.read_file(tmp)
      assert.are.equal(data, got)
      os.remove(tmp)
    end)

    it("read_file returns nil and an error for a missing path", function()
      local content, err = utils.read_file("/tmp/__no_such_file_ipynb_test__")
      assert.is_nil(content)
      assert.is_string(err)
    end)

    it("write_file returns false and an error for an unwritable path", function()
      local ok, err = utils.write_file("/no_permission_dir_ipynb/__file__", "x")
      assert.is_false(ok)
      assert.is_string(err)
    end)
  end)

  -- ── M.log() / M.warn() / M.err() / M.info() ─────────────────────────────────

  describe("M.log() family", function()
    it("calls vim.notify with [ipynb] prefix", function()
      local captured = {}
      local orig = vim.notify
      vim.notify = function(msg, level)
        captured[#captured + 1] = { msg = msg, level = level }
      end

      utils.info("test message")

      assert.are.equal(1, #captured)
      assert.is_truthy(captured[1].msg:match("^%[ipynb%]"))
      assert.is_truthy(captured[1].msg:match("test message"))

      vim.notify = orig
    end)

    it("M.warn uses WARN level", function()
      local captured_level
      local orig = vim.notify
      vim.notify = function(_, level)
        captured_level = level
      end

      utils.warn("w")

      assert.are.equal(vim.log.levels.WARN, captured_level)
      vim.notify = orig
    end)

    it("M.err uses ERROR level", function()
      local captured_level
      local orig = vim.notify
      vim.notify = function(_, level)
        captured_level = level
      end

      utils.err("e")

      assert.are.equal(vim.log.levels.ERROR, captured_level)
      vim.notify = orig
    end)
  end)
end)
