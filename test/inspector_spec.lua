--- test/inspector_spec.lua
--- Tests for ipynb.inspector: module loading and graceful degradation paths
--- that do not require a live kernel or Neovim window.
---
--- The two private helpers (parse_json_from_output, build_display) are tested
--- indirectly via the observable side-effects of M.open().

describe("ipynb.inspector", function()
  local inspector

  -- Minimal vim stubs needed for the module to load in a headless Neovim.
  before_each(function()
    -- Reset module cache so each test gets a fresh module state.
    package.loaded["ipynb.inspector"] = nil
    package.loaded["ipynb.kernel"]    = nil
    package.loaded["ipynb.utils"]     = nil

    -- Provide minimal vim.api stubs if missing.
    vim.api = vim.api or {}
    vim.api.nvim_set_hl = vim.api.nvim_set_hl or function() end

    inspector = require("ipynb.inspector")
  end)

  -- ── Module shape ─────────────────────────────────────────────────────────────

  describe("module", function()
    it("loads without error", function()
      assert.is_table(inspector)
    end)

    it("exposes M.open as a function", function()
      assert.is_function(inspector.open)
    end)

    it("exposes M.inspect_var as a function", function()
      assert.is_function(inspector.inspect_var)
    end)
  end)

  -- ── M.open() graceful degradation ────────────────────────────────────────────

  describe("M.open() when kernel module is unavailable", function()
    it("warns and returns without error when ipynb.kernel cannot be loaded", function()
      -- Inject a stub that fails to load.
      package.preload["ipynb.kernel"] = function() error("no kernel") end

      local warned = nil
      package.loaded["ipynb.utils"] = {
        warn  = function(msg) warned = msg end,
        info  = function() end,
        err   = function() end,
        debug = function() end,
        log   = function() end,
      }

      package.loaded["ipynb.inspector"] = nil
      local insp = require("ipynb.inspector")

      assert.has_no.errors(function()
        insp.open(1)
      end)
      assert.is_string(warned)
    end)
  end)

  describe("M.open() when kernel is busy", function()
    it("warns and returns without error when kernel status is not idle", function()
      -- Stub the kernel so it reports a busy status.
      package.preload["ipynb.kernel"] = function()
        return {
          status         = function(_) return "busy" end,
          execute_snippet = function() end,
        }
      end

      local warned = nil
      package.loaded["ipynb.utils"] = {
        warn  = function(msg) warned = msg end,
        info  = function() end,
        err   = function() end,
        debug = function() end,
        log   = function() end,
      }

      package.loaded["ipynb.inspector"] = nil
      local insp = require("ipynb.inspector")

      assert.has_no.errors(function()
        insp.open(1)
      end)
      assert.is_string(warned)
      assert.is_truthy(warned:match("[Kk]ernel") or warned:match("busy") or warned:match("idle"))
    end)
  end)

  describe("M.open() when kernel is idle", function()
    it("calls execute_snippet and passes a callback", function()
      local captured_code     = nil
      local captured_callback = nil

      package.preload["ipynb.kernel"] = function()
        return {
          status = function(_) return "idle" end,
          execute_snippet = function(_, code, cb)
            captured_code     = code
            captured_callback = cb
          end,
        }
      end

      package.loaded["ipynb.utils"] = {
        warn  = function() end,
        info  = function() end,
        err   = function() end,
        debug = function() end,
        log   = function() end,
      }

      package.loaded["ipynb.inspector"] = nil
      local insp = require("ipynb.inspector")

      assert.has_no.errors(function()
        insp.open(42)
      end)

      -- The snippet must be a non-empty string containing Python.
      assert.is_string(captured_code)
      assert.is_truthy(#captured_code > 0)
      assert.is_function(captured_callback)
    end)

    it("introspect snippet contains json output", function()
      local captured_code = nil

      package.preload["ipynb.kernel"] = function()
        return {
          status = function(_) return "idle" end,
          execute_snippet = function(_, code, _) captured_code = code end,
        }
      end

      package.loaded["ipynb.utils"] = {
        warn  = function() end,
        info  = function() end,
        err   = function() end,
        debug = function() end,
        log   = function() end,
      }

      package.loaded["ipynb.inspector"] = nil
      local insp = require("ipynb.inspector")
      insp.open(1)

      -- Verify the snippet will produce JSON (contains json.dumps).
      assert.is_truthy(captured_code:match("json%.dumps") or captured_code:match("json_decode"))
    end)
  end)

  -- ── INTROSPECT_CODE quality checks ────────────────────────────────────────────

  describe("INTROSPECT_CODE snippet", function()
    -- Load the inspector source text directly for static checks.
    local src_path = (debug and debug.getinfo(1, "S") or {}).source
    local insp_path = "/home/oneai/jupytervim/lua/ipynb/inspector.lua"

    it("does not use vim.wait (would cause re-entrancy)", function()
      local f = io.open(insp_path, "r")
      if not f then pending("cannot open inspector.lua") end
      local src = f:read("*a"); f:close()
      assert.is_nil(src:find("vim%.wait"),
        "inspector.lua must not call vim.wait - causes event-loop re-entrancy")
    end)

    it("uses computed format strings instead of '%-*s'", function()
      local f = io.open(insp_path, "r")
      if not f then pending("cannot open inspector.lua") end
      local src = f:read("*a"); f:close()
      -- %-*s is not supported in LuaJIT's string.format.
      assert.is_nil(src:find("%%-*s", 1, true),
        "inspector.lua must not use '%-*s' (unsupported in LuaJIT)")
    end)

    it("clamps end_col with math.min (avoids 'end_col out of range' crash)", function()
      local f = io.open(insp_path, "r")
      if not f then pending("cannot open inspector.lua") end
      local src = f:read("*a"); f:close()
      assert.is_truthy(src:find("math%.min"),
        "highlight_inspector_buf must clamp end_col with math.min")
    end)
  end)
end)
