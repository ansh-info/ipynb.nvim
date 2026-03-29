--- test/cell_spec.lua
--- Tests for ipynb.cell: state accessors, module shape, and static checks.
---
--- render() and extmark mutation functions require a live Neovim event loop
--- and are covered in headless_test.lua.  This spec tests the parts that are
--- exercisable with a plain vim.api scratch buffer.

describe("ipynb.cell", function()
  local cell

  before_each(function()
    package.loaded["ipynb.cell"]     = nil
    package.loaded["ipynb.config"]   = nil
    package.loaded["ipynb.utils"]    = nil
    package.loaded["ipynb.notebook"] = nil
    package.loaded["ipynb.markdown"] = nil

    -- Stub markdown so render() does not depend on it being installed.
    package.preload["ipynb.markdown"] = function()
      return { render = function() end }
    end

    cell = require("ipynb.cell")
  end)

  -- ── Module shape ──────────────────────────────────────────────────────────────

  describe("module", function()
    it("loads without error", function()
      assert.is_table(cell)
    end)

    it("exposes expected public functions", function()
      assert.is_function(cell.render)
      assert.is_function(cell.get_cells)
      assert.is_function(cell.get_notebook)
      assert.is_function(cell.on_buf_delete)
      assert.is_function(cell.namespace)
      assert.is_function(cell.cell_at_cursor)
      assert.is_function(cell.goto_next_cell)
      assert.is_function(cell.goto_prev_cell)
      assert.is_function(cell.get_cell_source)
      assert.is_function(cell.cells_above)
      assert.is_function(cell.add_cell_below)
      assert.is_function(cell.add_cell_above)
      assert.is_function(cell.delete_cell)
      assert.is_function(cell.set_output_virt_lines)
      assert.is_function(cell.clear_output)
      assert.is_function(cell.update_status)
      assert.is_function(cell.update_execution_count)
      assert.is_function(cell.reanchor_end_marks)
    end)

    it("namespace() returns an integer", function()
      local ns = cell.namespace()
      assert.is_number(ns)
      assert.is_true(ns >= 0)
    end)
  end)

  -- ── State accessors for unknown buffer ───────────────────────────────────────

  describe("state accessors", function()
    it("get_cells returns an empty table for an unknown buffer", function()
      local cells = cell.get_cells(99999)
      assert.is_table(cells)
      assert.are.equal(0, #cells)
    end)

    it("get_notebook returns nil for an unknown buffer", function()
      assert.is_nil(cell.get_notebook(99999))
    end)

    it("on_buf_delete does not error for an unknown buffer", function()
      assert.has_no.errors(function()
        cell.on_buf_delete(99999)
      end)
    end)

    it("on_buf_delete clears state", function()
      -- After a delete the state should still be accessible (lazily re-created)
      -- but return empty cells.
      cell.on_buf_delete(12345)
      assert.are.equal(0, #cell.get_cells(12345))
      assert.is_nil(cell.get_notebook(12345))
    end)
  end)

  -- ── delete_cell guard ─────────────────────────────────────────────────────────

  describe("delete_cell guard", function()
    it("warns and returns when trying to delete the only cell", function()
      -- Build a minimal buf_state by calling render() on a real scratch buffer.
      -- We need ipynb.notebook to be available.
      package.loaded["ipynb.notebook"] = nil
      local nb_mod = require("ipynb.notebook")
      local utils  = require("ipynb.utils")

      local warned = nil
      local orig_warn = utils.warn
      utils.warn = function(msg) warned = msg end

      -- Create a real scratch buffer with one line.
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "x = 1" })

      -- Build a minimal notebook with one cell.
      local notebook = nb_mod.parse({
        nbformat = 4,
        metadata = {},
        cells    = { { id = "cc", cell_type = "code", source = "x = 1", outputs = {}, metadata = {} } },
      }, "/tmp/one_cell.ipynb")

      -- Render into the scratch buffer (calls vim.api for real).
      cell.render(bufnr, notebook)

      -- Now try to delete the only cell.
      cell.delete_cell(bufnr, 1)

      assert.is_string(warned)
      assert.is_truthy(warned:match("[Cc]annot") or warned:match("only") or warned:match("delete"))

      utils.warn = orig_warn
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  end)

  -- ── cells_above ──────────────────────────────────────────────────────────────

  describe("cells_above()", function()
    it("returns empty list when up_to is 1", function()
      -- No state needed - up_to - 1 = 0 so the loop body never runs.
      local result = cell.cells_above(99998, 1)
      assert.is_table(result)
      assert.are.equal(0, #result)
    end)
  end)

  -- ── Static checks ─────────────────────────────────────────────────────────────

  describe("reanchor_end_marks source checks", function()
    local src_path = "/home/oneai/jupytervim/lua/ipynb/cell.lua"

    it("uses next_start - 2 formula for end boundary", function()
      local f = io.open(src_path, "r")
      if not f then pending("cannot open cell.lua") end
      local src = f:read("*a"); f:close()
      -- The separator formula: end = next_start - 2
      assert.is_truthy(src:find("next_sm%[1%]%s*%-%s*2"),
        "reanchor_end_marks must use 'next_sm[1] - 2' formula")
    end)

    it("guards against an empty cells list", function()
      local f = io.open(src_path, "r")
      if not f then pending("cannot open cell.lua") end
      local src = f:read("*a"); f:close()
      assert.is_truthy(src:find("#state%.cells%s*==%s*0"),
        "reanchor_end_marks must guard against empty cells list")
    end)
  end)
end)
