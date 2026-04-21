--- test/notebook_spec.lua
--- Tests for ipynb.notebook: parse, save round-trip, kernel_name, cell_language.

describe("ipynb.notebook", function()
  local nb

  before_each(function()
    package.loaded["ipynb.core.notebook"] = nil
    package.loaded["ipynb.utils"] = nil
    nb = require("ipynb.core.notebook")
  end)

  -- ── Helpers ──────────────────────────────────────────────────────────────────

  local function make_raw_nb(cells, meta)
    return {
      nbformat = 4,
      nbformat_minor = 5,
      metadata = meta or {},
      cells = cells or {},
    }
  end

  local function code_cell(src, id)
    return {
      id = id or "aabbccdd",
      cell_type = "code",
      source = src,
      outputs = {},
      metadata = {},
      execution_count = nil,
    }
  end

  local function md_cell(src)
    return { id = "11223344", cell_type = "markdown", source = src, metadata = {} }
  end

  -- ── M.parse() ────────────────────────────────────────────────────────────────

  describe("M.parse()", function()
    it("returns a notebook table with path", function()
      local raw = make_raw_nb({})
      local notebook, err = nb.parse(raw, "/tmp/test.ipynb")
      assert.is_nil(err)
      assert.are.equal("/tmp/test.ipynb", notebook.path)
      assert.are.equal(4, notebook.nbformat)
    end)

    it("parses a code cell with string source", function()
      local raw = make_raw_nb({ code_cell("print(1)") })
      local notebook = nb.parse(raw, "/tmp/t.ipynb")
      assert.are.equal(1, #notebook.cells)
      assert.are.equal("code", notebook.cells[1].cell_type)
      assert.are.equal("print(1)", notebook.cells[1].source)
    end)

    it("joins list source into a single string", function()
      local raw = make_raw_nb({
        {
          id = "aa",
          cell_type = "code",
          source = { "x = 1\n", "print(x)\n" },
          outputs = {},
          metadata = {},
        },
      })
      local notebook = nb.parse(raw, "/tmp/t.ipynb")
      assert.are.equal("x = 1\nprint(x)\n", notebook.cells[1].source)
    end)

    it("parses a markdown cell", function()
      local raw = make_raw_nb({ md_cell("# Hello") })
      local notebook = nb.parse(raw, "/tmp/t.ipynb")
      assert.are.equal("markdown", notebook.cells[1].cell_type)
      assert.are.equal("# Hello", notebook.cells[1].source)
    end)

    it("generates a cell id when missing", function()
      local raw = make_raw_nb({
        { cell_type = "code", source = "x=1", outputs = {}, metadata = {} },
      })
      local notebook = nb.parse(raw, "/tmp/t.ipynb")
      assert.is_string(notebook.cells[1].id)
      assert.is_truthy(#notebook.cells[1].id > 0)
    end)

    it("rejects nbformat < 3", function()
      local raw = { nbformat = 2, cells = {}, metadata = {} }
      local notebook, err = nb.parse(raw, "/tmp/t.ipynb")
      assert.is_nil(notebook)
      assert.is_string(err)
      assert.is_truthy(err:match("unsupported"))
    end)

    it("accepts nbformat 3 via worksheets", function()
      local raw = {
        nbformat = 3,
        metadata = {},
        worksheets = {
          {
            cells = {
              { cell_type = "code", input = "1+1", source = "1+1", outputs = {}, metadata = {} },
            },
          },
        },
      }
      local notebook, err = nb.parse(raw, "/tmp/t.ipynb")
      assert.is_nil(err)
      assert.are.equal(1, #notebook.cells)
    end)

    it("parses multiple cells in order", function()
      local raw = make_raw_nb({
        code_cell("a=1", "cell1"),
        md_cell("## Two"),
        code_cell("b=2", "cell3"),
      })
      local notebook = nb.parse(raw, "/tmp/t.ipynb")
      assert.are.equal(3, #notebook.cells)
      assert.are.equal("code", notebook.cells[1].cell_type)
      assert.are.equal("markdown", notebook.cells[2].cell_type)
      assert.are.equal("code", notebook.cells[3].cell_type)
    end)

    it("preserves notebook-level metadata", function()
      local meta = { kernelspec = { name = "python3", language = "python" } }
      local raw = make_raw_nb({}, meta)
      local notebook = nb.parse(raw, "/tmp/t.ipynb")
      assert.are.equal("python3", notebook.metadata.kernelspec.name)
    end)
  end)

  -- ── M.kernel_name() ──────────────────────────────────────────────────────────

  describe("M.kernel_name()", function()
    it("returns python3 when metadata is empty", function()
      local notebook = { metadata = {} }
      assert.are.equal("python3", nb.kernel_name(notebook))
    end)

    it("returns the kernelspec name when set", function()
      local notebook = { metadata = { kernelspec = { name = "ir" } } }
      assert.are.equal("ir", nb.kernel_name(notebook))
    end)
  end)

  -- ── M.cell_language() ────────────────────────────────────────────────────────

  describe("M.cell_language()", function()
    local function empty_notebook()
      return { metadata = {} }
    end

    it("returns markdown for markdown cells", function()
      assert.are.equal("markdown", nb.cell_language(empty_notebook(), { cell_type = "markdown" }))
    end)

    it("returns raw for raw cells", function()
      assert.are.equal("raw", nb.cell_language(empty_notebook(), { cell_type = "raw" }))
    end)

    it("returns python from kernelspec.language", function()
      local notebook = { metadata = { kernelspec = { language = "python" } } }
      assert.are.equal("python", nb.cell_language(notebook, { cell_type = "code" }))
    end)

    it("returns language from language_info when kernelspec absent", function()
      local notebook = { metadata = { language_info = { name = "julia" } } }
      assert.are.equal("julia", nb.cell_language(notebook, { cell_type = "code" }))
    end)

    it("defaults to python when metadata is empty", function()
      assert.are.equal("python", nb.cell_language(empty_notebook(), { cell_type = "code" }))
    end)
  end)

  -- ── M.save() + M.parse() round-trip ─────────────────────────────────────────

  describe("round-trip save / parse", function()
    it("preserves cell sources through save + load", function()
      local tmp = os.tmpname() .. ".ipynb"
      local raw = make_raw_nb({ code_cell("x = 42\nprint(x)"), md_cell("# Title") })
      local notebook, _ = nb.parse(raw, tmp)

      local ok, err = nb.save(notebook)
      assert.is_true(ok, "save failed: " .. tostring(err))

      -- Re-parse the written file using load().
      local notebook2, err2 = nb.load(tmp)
      assert.is_nil(err2, "load failed: " .. tostring(err2))
      assert.are.equal(2, #notebook2.cells)
      assert.are.equal("x = 42\nprint(x)", notebook2.cells[1].source)
      assert.are.equal("# Title", notebook2.cells[2].source)

      os.remove(tmp)
    end)

    it("preserves cell types through round-trip", function()
      local tmp = os.tmpname() .. ".ipynb"
      local raw = make_raw_nb({ code_cell("a=1"), md_cell("hi") })
      local notebook = nb.parse(raw, tmp)
      nb.save(notebook)

      local notebook2 = nb.load(tmp)
      assert.are.equal("code", notebook2.cells[1].cell_type)
      assert.are.equal("markdown", notebook2.cells[2].cell_type)
      os.remove(tmp)
    end)

    it("saves with 1-space indented JSON for git-friendly diffs", function()
      local tmp = os.tmpname() .. ".ipynb"
      local raw = make_raw_nb({ code_cell("x=1", "aabbccdd") })
      local notebook = nb.parse(raw, tmp)
      nb.save(notebook)

      local f = io.open(tmp, "r")
      local content = f:read("*a")
      f:close()

      local lines = vim.split(content, "\n", { plain = true })
      assert.are.equal("{", lines[1], "expected top-level opening brace on first line")
      assert.is_truthy(lines[2]:match('^ "cells":'), "expected 1-space indented keys")

      local has_cell_type = false
      for _, line in ipairs(lines) do
        if line:match('^  "cell_type":') then
          has_cell_type = true
          break
        end
      end
      assert.is_true(has_cell_type, "expected 2-space indent for cell fields")
      assert.are.equal("", lines[#lines], "expected trailing newline")
      assert.are.equal("}", lines[#lines - 1], "expected closing brace on last content line")

      os.remove(tmp)
    end)

    it("encodes NaN and Infinity as null for valid JSON", function()
      local tmp = os.tmpname() .. ".ipynb"
      local raw = make_raw_nb({ code_cell("x=1", "aabbccdd") })
      local notebook = nb.parse(raw, tmp)
      notebook.cells[1].execution_count = 0 / 0 -- NaN
      notebook.cells[1].metadata = { inf_val = math.huge, neg_inf = -math.huge }

      local ok, err = nb.save(notebook)
      assert.is_true(ok, "save failed: " .. tostring(err))

      local f = io.open(tmp, "r")
      local content = f:read("*a")
      f:close()

      assert.is_nil(content:match("NaN"), "NaN must not appear in saved JSON")
      assert.is_nil(content:match("Infinity"), "Infinity must not appear in saved JSON")

      local notebook2, err2 = nb.load(tmp)
      assert.is_nil(err2, "re-open failed: " .. tostring(err2))
      assert.is_not_nil(notebook2, "notebook should be parseable after save")

      os.remove(tmp)
    end)

    it("saves empty metadata as {} not multi-line", function()
      local tmp = os.tmpname() .. ".ipynb"
      local raw = make_raw_nb({ code_cell("x=1", "aabbccdd") })
      local notebook = nb.parse(raw, tmp)
      nb.save(notebook)

      local f = io.open(tmp, "r")
      local content = f:read("*a")
      f:close()

      local has_compact_metadata = false
      for line in content:gmatch("[^\n]+") do
        if line:match('"metadata": {}') then
          has_compact_metadata = true
          break
        end
      end
      assert.is_true(has_compact_metadata, "empty metadata should be compact {}")

      os.remove(tmp)
    end)
  end)
end)
