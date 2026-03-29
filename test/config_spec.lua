--- test/config_spec.lua
--- Tests for ipynb.config: defaults, deep-merge, get() behaviour.

describe("ipynb.config", function()
  local config

  before_each(function()
    package.loaded["ipynb.config"] = nil
    config = require("ipynb.config")
  end)

  -- ── M.get() ──────────────────────────────────────────────────────────────

  describe("M.get()", function()
    it("returns a table even when setup() was never called", function()
      assert.is_table(config.get())
    end)

    it("has the expected top-level keys", function()
      local cfg = config.get()
      assert.is_table(cfg.kernel)
      assert.is_table(cfg.ui)
      assert.is_table(cfg.keymaps)
      assert.is_table(cfg.image)
      assert.is_table(cfg.notebook)
    end)

    it("returns default kernel settings", function()
      local cfg = config.get()
      assert.are.equal("python3", cfg.kernel.default_kernel)
      assert.is_true(cfg.kernel.auto_start)
    end)

    it("returns default ui settings", function()
      local cfg = config.get()
      assert.are.equal(50, cfg.ui.output_max_lines)
      assert.is_true(cfg.ui.show_execution_count)
      assert.is_true(cfg.ui.show_elapsed_time)
    end)

    it("returns default border_chars", function()
      local bc = config.get().ui.border_chars
      assert.are.equal("╭", bc.top_left)
      assert.are.equal("╮", bc.top_right)
      assert.are.equal("╰", bc.bottom_left)
      assert.are.equal("╯", bc.bottom_right)
      assert.are.equal("─", bc.horizontal)
    end)

    it("returns the same table on repeated calls", function()
      local a = config.get()
      local b = config.get()
      assert.are.equal(a, b)
    end)

    it("has image enabled by default", function()
      assert.is_true(config.get().image.enabled)
    end)

    it("has keymaps enabled by default", function()
      assert.is_true(config.get().keymaps.enabled)
    end)

    it("has auto_save disabled by default", function()
      assert.is_false(config.get().notebook.auto_save)
    end)
  end)

  -- ── M.setup() ─────────────────────────────────────────────────────────────

  describe("M.setup(opts)", function()
    it("accepts empty opts without error", function()
      assert.has_no.errors(function()
        config.setup({})
      end)
    end)

    it("accepts nil opts without error", function()
      assert.has_no.errors(function()
        config.setup(nil)
      end)
    end)

    it("overrides a single leaf value without clobbering siblings", function()
      config.setup({ ui = { output_max_lines = 200 } })
      local cfg = config.get()
      assert.are.equal(200, cfg.ui.output_max_lines)
      -- siblings must survive
      assert.is_true(cfg.ui.show_execution_count)
      assert.is_true(cfg.ui.show_elapsed_time)
    end)

    it("overrides nested kernel config", function()
      config.setup({ kernel = { auto_start = false, default_kernel = "pypy3" } })
      local cfg = config.get()
      assert.is_false(cfg.kernel.auto_start)
      assert.are.equal("pypy3", cfg.kernel.default_kernel)
    end)

    it("does not clobber unrelated top-level sections", function()
      config.setup({ ui = { output_max_lines = 10 } })
      local cfg = config.get()
      -- kernel section must still have defaults
      assert.are.equal("python3", cfg.kernel.default_kernel)
      assert.is_true(cfg.kernel.auto_start)
    end)

    it("can disable image support", function()
      config.setup({ image = { enabled = false } })
      assert.is_false(config.get().image.enabled)
    end)

    it("can override a single border char", function()
      config.setup({ ui = { border_chars = { top_left = "+" } } })
      assert.are.equal("+", config.get().ui.border_chars.top_left)
    end)

    it("can override notebook auto_save", function()
      config.setup({ notebook = { auto_save = true } })
      assert.is_true(config.get().notebook.auto_save)
    end)

    it("can override a keymap binding", function()
      config.setup({ keymaps = { run_cell = "<F5>" } })
      assert.are.equal("<F5>", config.get().keymaps.run_cell)
    end)

    it("does not clobber other keymap bindings when one is overridden", function()
      config.setup({ keymaps = { run_cell = "<F5>" } })
      local km = config.get().keymaps
      assert.is_true(km.enabled)
      assert.are.equal("]c", km.next_cell)
      assert.are.equal("[c", km.prev_cell)
    end)
  end)
end)
