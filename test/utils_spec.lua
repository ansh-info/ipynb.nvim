--- test/utils_spec.lua
--- Tests for ipynb.utils: pure-Lua helpers that do not require a real Neovim session.

describe("ipynb.utils", function()
  local utils

  before_each(function()
    package.loaded["ipynb.utils"] = nil
    utils = require("ipynb.utils")
  end)

  -- ── M.split() ────────────────────────────────────────────────────────────────

  describe("M.split()", function()
    it("splits a string on a single character", function()
      local parts = utils.split("a,b,c", ",")
      assert.are.equal(3, #parts)
      assert.are.equal("a", parts[1])
      assert.are.equal("b", parts[2])
      assert.are.equal("c", parts[3])
    end)

    it("splits on slash delimiter", function()
      local parts = utils.split("foo/bar/baz", "/")
      assert.are.equal(3, #parts)
      assert.are.equal("foo", parts[1])
    end)

    it("returns a single element when delimiter is absent", function()
      local parts = utils.split("hello", ",")
      assert.are.equal(1, #parts)
      assert.are.equal("hello", parts[1])
    end)

    it("returns empty table for empty string", function()
      local parts = utils.split("", ",")
      assert.are.equal(0, #parts)
    end)
  end)

  -- ── M.tmpfile() ──────────────────────────────────────────────────────────────

  describe("M.tmpfile()", function()
    it("returns a string ending with the given extension", function()
      local path = utils.tmpfile("png")
      assert.is_string(path)
      assert.is_truthy(path:match("%.png$"))
    end)

    it("returns a different path on each call", function()
      local p1 = utils.tmpfile("txt")
      local p2 = utils.tmpfile("txt")
      assert.are_not.equal(p1, p2)
    end)
  end)

  -- ── M.uid() ──────────────────────────────────────────────────────────────────

  describe("M.uid()", function()
    it("returns a non-empty string", function()
      local id = utils.uid()
      assert.is_string(id)
      assert.is_truthy(#id > 0)
    end)

    it("returns a unique value on consecutive calls", function()
      -- Not guaranteed by the spec but almost certain in practice.
      local ids = {}
      for _ = 1, 20 do
        local id = utils.uid()
        assert.is_nil(ids[id], "duplicate uid: " .. id)
        ids[id] = true
      end
    end)
  end)

  -- ── M.has_plugin() ───────────────────────────────────────────────────────────

  describe("M.has_plugin()", function()
    it("returns false for a module that does not exist", function()
      assert.is_false(utils.has_plugin("__no_such_module_xyz__"))
    end)

    it("returns true for a module that does exist", function()
      -- 'string' is always available in Lua.
      assert.is_true(utils.has_plugin("string"))
    end)
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

  -- ── M.rpad() ─────────────────────────────────────────────────────────────────

  describe("M.rpad()", function()
    it("pads a string to the requested width", function()
      -- stub vim.fn.strdisplaywidth so the test works without Neovim
      local orig = vim.fn.strdisplaywidth
      vim.fn.strdisplaywidth = function(s)
        return #s
      end

      local result = utils.rpad("hi", 5)
      assert.are.equal("hi   ", result)

      vim.fn.strdisplaywidth = orig
    end)

    it("returns the string unchanged when already wide enough", function()
      local orig = vim.fn.strdisplaywidth
      vim.fn.strdisplaywidth = function(s)
        return #s
      end

      local result = utils.rpad("hello", 3)
      assert.are.equal("hello", result)

      vim.fn.strdisplaywidth = orig
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
