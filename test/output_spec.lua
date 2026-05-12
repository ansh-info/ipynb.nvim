--- test/output_spec.lua
--- Tests for ipynb.output: chunk accumulator, clear semantics, and
--- re-entrancy guard presence (static check).
---
--- Avoids testing vim.schedule callbacks directly - those paths require a
--- running Neovim event loop.  Instead we test the synchronous accumulator
--- behaviour and that the re-entrancy guards exist in source.

describe("ipynb.output", function()
  local output

  -- Stubs shared by all tests.
  local function make_cell_stub()
    return {
      clear_output = function() end,
      set_output_virt_lines = function() end,
    }
  end

  local function make_config_stub(max_lines)
    return {
      get = function()
        return { ui = { output_max_lines = max_lines or 50, output_max_store = 0 } }
      end,
    }
  end

  before_each(function()
    -- Reset all relevant modules.
    package.loaded["ipynb.kernel.output"] = nil
    package.loaded["ipynb.config"] = nil
    package.loaded["ipynb.core.cell"] = nil
    package.loaded["ipynb.ui.image"] = nil

    -- Stub dependencies before requiring output.
    package.preload["ipynb.config"] = function()
      return make_config_stub()
    end
    package.preload["ipynb.core.cell"] = function()
      return make_cell_stub()
    end
    -- image is optional; stub as unavailable so image paths are bypassed.
    package.preload["ipynb.ui.image"] = function()
      return {
        is_supported = function()
          return false
        end,
        clear = function() end,
        render = function() end,
        placeholder = function(_)
          return "(image)"
        end,
      }
    end

    output = require("ipynb.kernel.output")
  end)

  local function fake_cell(mark_id)
    return { start_mark = mark_id or 1, cell_id = "cell_" .. tostring(mark_id or 1) }
  end

  -- ── M.get_chunks() ───────────────────────────────────────────────────────────

  describe("M.get_chunks()", function()
    it("returns an empty table when no chunks have been stored", function()
      local chunks = output.get_chunks(1, fake_cell(1))
      assert.is_table(chunks)
      assert.are.equal(0, #chunks)
    end)

    it("returns distinct empty tables for different cells", function()
      local a = output.get_chunks(1, fake_cell(1))
      local b = output.get_chunks(1, fake_cell(2))
      assert.are_not.equal(a, b)
    end)
  end)

  -- ── M.append() ───────────────────────────────────────────────────────────────

  describe("M.append()", function()
    it("accumulates stream chunks", function()
      local cs = fake_cell(10)
      local chunk1 = { type = "stream", name = "stdout", text = "hello\n" }
      local chunk2 = { type = "stream", name = "stdout", text = "world\n" }
      output.append(1, cs, chunk1)
      output.append(1, cs, chunk2)
      local chunks = output.get_chunks(1, cs)
      assert.are.equal(2, #chunks)
      assert.are.equal("hello\n", chunks[1].text)
      assert.are.equal("world\n", chunks[2].text)
    end)

    it("accumulates result chunks", function()
      local cs = fake_cell(20)
      output.append(1, cs, { type = "result", text = "42" })
      assert.are.equal(1, #output.get_chunks(1, cs))
    end)

    it("accumulates error chunks", function()
      local cs = fake_cell(30)
      output.append(1, cs, { type = "error", ename = "ValueError", evalue = "bad", traceback = {} })
      assert.are.equal(1, #output.get_chunks(1, cs))
    end)

    it("isolates chunks per cell within the same buffer", function()
      local cs1 = fake_cell(1)
      local cs2 = fake_cell(2)
      output.append(1, cs1, { type = "stream", text = "a" })
      output.append(1, cs1, { type = "stream", text = "b" })
      output.append(1, cs2, { type = "stream", text = "c" })
      assert.are.equal(2, #output.get_chunks(1, cs1))
      assert.are.equal(1, #output.get_chunks(1, cs2))
    end)

    it("isolates chunks per buffer for the same cell mark", function()
      local cs = fake_cell(5)
      output.append(10, cs, { type = "stream", text = "buf10" })
      output.append(20, cs, { type = "stream", text = "buf20" })
      assert.are.equal(1, #output.get_chunks(10, cs))
      assert.are.equal(1, #output.get_chunks(20, cs))
    end)

    it("handles clear_output chunk by wiping stored chunks", function()
      local cs = fake_cell(50)
      output.append(1, cs, { type = "stream", text = "before" })
      assert.are.equal(1, #output.get_chunks(1, cs))

      output.append(1, cs, { type = "clear_output" })
      assert.are.equal(0, #output.get_chunks(1, cs))
    end)
  end)

  -- ── M.clear() ────────────────────────────────────────────────────────────────

  describe("M.clear()", function()
    it("removes stored chunks for the cell", function()
      local cs = fake_cell(99)
      output.append(1, cs, { type = "result", text = "x" })
      assert.are.equal(1, #output.get_chunks(1, cs))

      output.clear(1, cs)
      assert.are.equal(0, #output.get_chunks(1, cs))
    end)

    it("is idempotent when called on a cell with no chunks", function()
      local cs = fake_cell(77)
      assert.has_no.errors(function()
        output.clear(1, cs)
        output.clear(1, cs)
      end)
    end)

    it("does not affect chunks stored for other cells", function()
      local cs1 = fake_cell(1)
      local cs2 = fake_cell(2)
      output.append(1, cs1, { type = "stream", text = "a" })
      output.append(1, cs2, { type = "stream", text = "b" })
      output.clear(1, cs1)
      assert.are.equal(0, #output.get_chunks(1, cs1))
      assert.are.equal(1, #output.get_chunks(1, cs2))
    end)
  end)

  -- ── M.clear_all() ────────────────────────────────────────────────────────────

  describe("M.clear_all()", function()
    it("clears all cells passed in the list", function()
      local cs1 = fake_cell(1)
      local cs2 = fake_cell(2)
      local cs3 = fake_cell(3)
      output.append(1, cs1, { type = "stream", text = "a" })
      output.append(1, cs2, { type = "stream", text = "b" })
      output.append(1, cs3, { type = "stream", text = "c" })

      output.clear_all(1, { cs1, cs2, cs3 })

      assert.are.equal(0, #output.get_chunks(1, cs1))
      assert.are.equal(0, #output.get_chunks(1, cs2))
      assert.are.equal(0, #output.get_chunks(1, cs3))
    end)

    it("does not error when called with an empty list", function()
      assert.has_no.errors(function()
        output.clear_all(1, {})
      end)
    end)

    it("does not error when called with nil cells", function()
      assert.has_no.errors(function()
        output.clear_all(1, nil)
      end)
    end)
  end)

  -- ── Re-entrancy guard (static check) ─────────────────────────────────────────

  describe("re-entrancy guard", function()
    local src_path = vim.fn.getcwd() .. "/lua/ipynb/kernel/output.lua"

    it("_active guard is present in source", function()
      local f = io.open(src_path, "r")
      if not f then
        pending("cannot open output.lua")
      end
      local src = f:read("*a")
      f:close()
      assert.is_truthy(
        src:find("_active%[key%]"),
        "re-entrancy guard '_active[key]' not found in output.lua"
      )
    end)

    it("_pending guard is present in source", function()
      local f = io.open(src_path, "r")
      if not f then
        pending("cannot open output.lua")
      end
      local src = f:read("*a")
      f:close()
      assert.is_truthy(
        src:find("_pending%[key%]"),
        "re-entrancy guard '_pending[key]' not found in output.lua"
      )
    end)
  end)
end)
