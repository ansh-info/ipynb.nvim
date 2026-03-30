--- ipynb.kernel
--- Manages the kernel_bridge.py subprocess per buffer and routes all
--- Jupyter output messages to output.lua for rendering.
---
--- State per buffer:
---   {
---     job_id      : integer,    -- Neovim job handle (vim.fn.jobstart)
---     status      : string,     -- "starting"|"idle"|"busy"|"stopped"
---     kernel_name : string,
---     language    : string,     -- reported by kernel_info
---     version     : string,     -- language version
---     msg_counter : integer,    -- monotonic counter for Lua msg_ids
---     -- Map: lua_msg_id → { cell_state, bufnr, start_ms }
---     --   OR lua_msg_id → function  (for complete/inspect callbacks)
---     pending     : table,
---     -- Partial stdout line buffer (jobstart delivers chunks, not full lines)
---     line_buf    : string,
---   }

local config = require("ipynb.config")
local cell = require("ipynb.core.cell")
local output = require("ipynb.kernel.output")
local utils = require("ipynb.utils")

local M = {}

-- Per-buffer kernel state.
local _state = {}

-- ── Helpers ───────────────────────────────────────────────────────────────────

--- Return (creating if needed) the state table for a buffer.
---@param bufnr integer
---@return table
local function get_state(bufnr)
  if not _state[bufnr] then
    _state[bufnr] = {
      job_id = nil,
      status = "stopped",
      kernel_name = "",
      language = "",
      version = "",
      msg_counter = 0,
      pending = {},
      line_buf = "",
    }
  end
  return _state[bufnr]
end

--- Generate a unique Lua msg_id for this buffer.
---@param bufnr integer
---@return string
local function next_msg_id(bufnr)
  local s = get_state(bufnr)
  s.msg_counter = s.msg_counter + 1
  return "jvim_" .. tostring(bufnr) .. "_" .. tostring(s.msg_counter)
end

--- Absolute path to kernel_bridge.py, resolved from this file's location.
--- Works for both local dev trees and lazy.nvim installs.
---@return string
local function bridge_path()
  -- source is lua/ipynb/kernel/init.lua; :h:h:h:h walks to plugin root
  local this_file = debug.getinfo(1, "S").source:sub(2)
  local root = vim.fn.fnamemodify(this_file, ":h:h:h:h")
  return root .. "/python/kernel_bridge.py"
end

--- Prefer the uv venv Python; fall back to config python_path.
---@return string
local function python_exe()
  local cfg = config.get()
  local bp = bridge_path()
  local root = vim.fn.fnamemodify(bp, ":h:h") -- plugin root
  local venv_py = root .. "/python/.venv/bin/python"
  if vim.fn.executable(venv_py) == 1 then
    return venv_py
  end
  return cfg.kernel.python_path
end

--- Write one JSON-line command to the bridge's stdin.
---@param bufnr integer
---@param msg table
local function send(bufnr, msg)
  local s = get_state(bufnr)
  if not s.job_id then
    utils.warn("No kernel bridge running. Use :IpynbKernelStart.")
    return
  end
  vim.fn.chansend(s.job_id, vim.fn.json_encode(msg) .. "\n")
end

-- ── Notebook model helpers ────────────────────────────────────────────────────

--- Convert an internal output chunk to an nbformat output object for saving.
--- Mirrors the reverse of nb_output_to_chunks() in kernel/output.lua.
---@param chunk table   internal chunk (stream/result/error/image)
---@param exec_count integer|nil
---@return table|nil  nbformat output object, or nil if not convertible
local function chunk_to_nb_output(chunk, exec_count)
  local t = chunk.type
  if t == "stream" then
    return { output_type = "stream", name = chunk.name or "stdout", text = chunk.text or "" }
  elseif t == "result" then
    local data = { ["text/plain"] = chunk.text or "" }
    if chunk.html and chunk.html ~= "" then
      data["text/html"] = chunk.html
    end
    return {
      output_type = "execute_result",
      data = data,
      metadata = {},
      execution_count = exec_count,
    }
  elseif t == "error" then
    return {
      output_type = "error",
      ename = chunk.ename or "Error",
      evalue = chunk.evalue or "",
      traceback = chunk.traceback or {},
    }
  elseif t == "image" then
    return {
      output_type = "display_data",
      data = { [chunk.mime or "image/png"] = chunk.data or "" },
      metadata = {},
    }
  end
  return nil
end

--- Clear cell output from both the render store and the notebook model.
---@param bufnr integer
---@param cs table  cell_state
local function clear_cell_output(bufnr, cs)
  output.clear(bufnr, cs)
  local nb = cell.get_notebook(bufnr)
  if nb and cs.index and nb.cells[cs.index] then
    nb.cells[cs.index].outputs = {}
  end
end

-- ── Message dispatch ──────────────────────────────────────────────────────────

--- Route one parsed JSON message from the bridge to the appropriate handler.
---@param bufnr integer
---@param msg table
local function dispatch(bufnr, msg)
  local t = msg.type or ""
  local s = get_state(bufnr)
  local id = msg.msg_id or ""

  -- ── status ────────────────────────────────────────────────────────────────
  if t == "status" then
    local prev = s.status
    local state = msg.state or ""
    s.status = (state == "busy") and "busy" or "idle"
    -- First idle after spawning: kernel is ready. Notify the user.
    if prev == "starting" and s.status == "idle" then
      utils.info("Kernel ready (" .. (s.kernel_name ~= "" and s.kernel_name or "python3") .. ")")
    end

    local pending = (id ~= "") and s.pending[id] or nil
    if pending and type(pending) == "table" then
      if pending._snippet_cb then
        -- Snippet execution (e.g. variable inspector): signal done.
        if state == "idle" then
          pending._snippet_cb(table.concat(pending._accumulated, ""), nil)
          s.pending[id] = nil
        end
      else
        if state == "busy" then
          cell.update_status(bufnr, pending.cell_state, "busy", nil)
        elseif state == "idle" then
          local elapsed_ms = vim.loop.now() - pending.start_ms
          cell.update_status(bufnr, pending.cell_state, "idle", elapsed_ms)
          s.pending[id] = nil
          -- Auto-save after execution if configured.
          if config.get().notebook.auto_save then
            vim.schedule(function()
              local ok, nb_buf = pcall(require, "ipynb.core.notebook_buf")
              if ok and nb_buf.is_managed(bufnr) then
                nb_buf.save(bufnr)
              end
            end)
          end
        end
      end
    end

  -- ── execute_input (kernel echoes code back with execution count) ──────────
  elseif t == "execute_input" then
    local pending = (id ~= "") and s.pending[id] or nil
    if pending and type(pending) == "table" and not pending._snippet_cb and msg.exec_count then
      cell.update_execution_count(bufnr, pending.cell_state, msg.exec_count)
      local nb = cell.get_notebook(bufnr)
      if nb and pending.cell_state.index then
        nb.cells[pending.cell_state.index].execution_count = msg.exec_count
      end
    end

  -- ── output chunks (stream / result / error / image / clear_output) ────────
  elseif t == "stream" or t == "result" or t == "error" or t == "image" or t == "clear_output" then
    local pending = (id ~= "") and s.pending[id] or nil
    if pending and type(pending) == "table" then
      if pending._snippet_cb then
        -- Snippet: accumulate stdout text; ignore other output types.
        if t == "stream" and (msg.name or "stdout") == "stdout" then
          pending._accumulated[#pending._accumulated + 1] = msg.text or ""
        end
      else
        output.append(bufnr, pending.cell_state, msg)
        -- Persist to notebook model so save() writes the correct outputs.
        local nb = cell.get_notebook(bufnr)
        local ci = pending.cell_state.index
        if nb and ci and nb.cells[ci] then
          if t == "clear_output" then
            nb.cells[ci].outputs = {}
          else
            local nb_out = chunk_to_nb_output(msg, nb.cells[ci].execution_count)
            if nb_out then
              if not nb.cells[ci].outputs then
                nb.cells[ci].outputs = {}
              end
              nb.cells[ci].outputs[#nb.cells[ci].outputs + 1] = nb_out
            end
          end
        end
        if t == "error" then
          cell.update_status(bufnr, pending.cell_state, "error", nil)
        end
      end
    else
      utils.warn("output dropped — no pending cell for msg_id=" .. tostring(id) .. " type=" .. t)
    end

  -- ── kernel_info ───────────────────────────────────────────────────────────
  elseif t == "kernel_info" then
    s.language = msg.language or ""
    s.version = msg.version or ""
    utils.info(string.format("Kernel ready: %s %s", s.language, s.version))

  -- ── completions (callback stored in pending) ──────────────────────────────
  elseif t == "complete" then
    local cb = (id ~= "") and s.pending[id] or nil
    if type(cb) == "function" then
      cb(msg)
      s.pending[id] = nil
    end

  -- ── inspect ───────────────────────────────────────────────────────────────
  elseif t == "inspect" then
    local cb = (id ~= "") and s.pending[id] or nil
    if type(cb) == "function" then
      cb(msg)
      s.pending[id] = nil
    end

  -- ── internal bridge errors ────────────────────────────────────────────────
  elseif t == "error_internal" then
    -- Suppress "No kernel connected" during the brief startup window — the
    -- auto-start polling loop will retry once the kernel is actually ready.
    local m = msg.message or "unknown error"
    if not m:find("No kernel connected") then
      utils.err("kernel_bridge: " .. m)
    end
  end
end

-- ── stdout line assembler ─────────────────────────────────────────────────────

--- Neovim jobstart delivers stdout with newlines REMOVED.
--- Each element of `data` is the text between two consecutive newlines.
--- data[1] is a continuation of the previous incomplete line;
--- data[i>1] means a newline separated data[i-1] from data[i].
---@param bufnr integer
---@param data string[]
local function on_stdout_chunks(bufnr, data)
  local s = get_state(bufnr)
  for i, chunk in ipairs(data) do
    if i == 1 then
      -- First element continues the previous (possibly empty) incomplete line.
      s.line_buf = s.line_buf .. chunk
    else
      -- A newline boundary occurred: s.line_buf is now a complete line.
      local line = vim.trim(s.line_buf)
      s.line_buf = chunk -- start accumulating the next line
      if line ~= "" then
        local ok, msg = pcall(vim.fn.json_decode, line)
        if ok and type(msg) == "table" then
          dispatch(bufnr, msg)
        else
          utils.debug("kernel_bridge non-JSON: " .. line)
        end
      end
    end
  end
end

-- ── Bridge spawn helper ───────────────────────────────────────────────────────

--- Spawn the kernel_bridge.py process and wire up all job callbacks.
--- Returns the job_id, or nil on failure.
---@param bufnr integer
---@return integer|nil
local function spawn_bridge(bufnr)
  local py = python_exe()
  local bp = bridge_path()

  if vim.fn.filereadable(bp) == 0 then
    utils.err("kernel_bridge.py not found: " .. bp)
    return nil
  end

  local job_id = vim.fn.jobstart({ py, bp }, {
    on_stdout = function(_, data, _)
      on_stdout_chunks(bufnr, data)
    end,
    on_stderr = function(_, data, _)
      local msg = table.concat(data, ""):gsub("%s+$", "")
      if msg ~= "" then
        utils.debug("kernel_bridge stderr: " .. msg)
      end
    end,
    on_exit = function(_, code, _)
      local st = get_state(bufnr)
      -- was_unexpected: status != "stopped" means the user did not request this exit
      local was_unexpected = st.status ~= "stopped"
      local was_starting = st.status == "starting"
      st.job_id = nil
      st.status = "stopped"

      if was_unexpected then
        -- Mark any cells that were running as errored so they don't stay busy.
        for _, pending in pairs(st.pending) do
          if type(pending) == "table" and pending.cell_state and not pending._snippet_cb then
            pcall(cell.update_status, bufnr, pending.cell_state, "error", nil)
          elseif type(pending) == "table" and pending._snippet_cb then
            pending._snippet_cb(nil, "Kernel stopped.")
          end
        end
        st.pending = {}

        if was_starting then
          utils.err(
            string.format("Kernel failed to start (exit %d). Check :messages for details.", code)
          )
        else
          utils.err(
            string.format(
              "Kernel stopped unexpectedly (exit %d). Run :IpynbKernelRestart to recover.",
              code
            )
          )
        end
      end
    end,
    stdout_buffered = false,
    stderr_buffered = false,
  })

  if job_id <= 0 then
    utils.err("Failed to spawn kernel bridge. Python: " .. py)
    return nil
  end
  return job_id
end

-- ── Public API ────────────────────────────────────────────────────────────────

--- Start a new kernel for the buffer.
---@param bufnr integer
---@param kernel_name string|nil  overrides config default
function M.start(bufnr, kernel_name)
  local s = get_state(bufnr)
  local cfg = config.get()

  if s.job_id then
    utils.warn("Kernel already running. Use :IpynbKernelRestart to restart.")
    return
  end

  local kn = kernel_name or cfg.kernel.default_kernel
  s.kernel_name = kn
  s.status = "starting"
  s.line_buf = ""

  local job_id = spawn_bridge(bufnr)
  if not job_id then
    return
  end
  s.job_id = job_id

  send(bufnr, { cmd = "start", kernel = kn })
  utils.info("Starting " .. kn .. " kernel…")
end

--- Stop the kernel and shut down the bridge process.
---@param bufnr integer
function M.stop(bufnr)
  local s = get_state(bufnr)
  if not s.job_id then
    utils.warn("No kernel running.")
    return
  end
  -- Mark stopped before the exit fires so on_exit knows this was intentional.
  s.status = "stopped"
  send(bufnr, { cmd = "shutdown" })
  vim.defer_fn(function()
    if s.job_id then
      vim.fn.jobstop(s.job_id)
    end
  end, 500)
  utils.info("Kernel stopped.")
end

--- Restart the kernel, clearing all cell outputs.
---@param bufnr integer
function M.restart(bufnr)
  local s = get_state(bufnr)
  local kn = s.kernel_name
  output.clear_all(bufnr, cell.get_cells(bufnr))
  M.stop(bufnr)
  vim.defer_fn(function()
    _state[bufnr] = nil
    M.start(bufnr, kn)
  end, 700)
end

--- Attach to an already-running kernel via its connection file.
---@param bufnr integer
---@param connection_file string|nil
function M.attach(bufnr, connection_file)
  local s = get_state(bufnr)
  if s.job_id then
    utils.warn("Stop the current kernel first.")
    return
  end

  s.line_buf = ""
  local job_id = spawn_bridge(bufnr)
  if not job_id then
    return
  end
  s.job_id = job_id

  local cmd = { cmd = "attach" }
  if connection_file then
    cmd.connection_file = connection_file
  end
  send(bufnr, cmd)
end

--- Send an interrupt signal to the kernel.
---@param bufnr integer
function M.interrupt(bufnr)
  send(bufnr, { cmd = "interrupt" })
  utils.info("Interrupt sent.")
end

--- Execute the cell the cursor is currently inside.
---@param bufnr integer
function M.run_current_cell(bufnr)
  local cfg = config.get()
  local cs, _ = cell.cell_at_cursor(bufnr)
  if not cs then
    utils.warn("Cursor is not inside a cell.")
    return
  end
  if cs.cell_type ~= "code" then
    utils.info("Not a code cell - skipping execution.")
    return
  end

  local s = get_state(bufnr)
  if not s.job_id then
    if cfg.kernel.auto_start then
      M.start(bufnr, nil)
      -- Poll every 500 ms until the kernel signals idle, then run.
      local function _await_and_run()
        local st = get_state(bufnr)
        if not st.job_id or st.status == "stopped" then
          return
        end
        if st.status == "idle" then
          M.run_current_cell(bufnr)
        else
          vim.defer_fn(_await_and_run, 500)
        end
      end
      vim.defer_fn(_await_and_run, 500)
      return
    end
    utils.warn("No kernel running. Use :IpynbKernelStart.")
    return
  end

  clear_cell_output(bufnr, cs)

  local mid = next_msg_id(bufnr)
  s.pending[mid] = { cell_state = cs, bufnr = bufnr, start_ms = vim.loop.now() }

  cell.update_status(bufnr, cs, "busy", nil)
  local code = cell.get_cell_source(bufnr, cs)
  utils.info("Executing cell [" .. mid .. "]: " .. vim.trim(code):sub(1, 40))
  send(bufnr, { cmd = "execute", code = code, msg_id = mid })
end

--- Execute the current cell and advance to the next one.
--- If the cursor is on the last cell, a new code cell is created below it.
--- Mirrors the Shift+Enter behaviour in Jupyter Lab / Colab.
---@param bufnr integer
function M.run_cell_and_advance(bufnr)
  local cs, idx = cell.cell_at_cursor(bufnr)
  if not cs then
    utils.warn("Cursor is not inside a cell.")
    return
  end

  -- Execute (non-blocking - kernel runs in background).
  M.run_current_cell(bufnr)

  -- Advance immediately, like Jupyter - don't wait for execution to finish.
  local cells = cell.get_cells(bufnr)
  if idx and idx < #cells then
    cell.goto_next_cell(bufnr)
  elseif idx then
    -- Last cell - create a new code cell below and move into it.
    cell.add_cell_below(bufnr, idx)
    vim.schedule(function()
      cell.goto_next_cell(bufnr)
    end)
  end
end

--- Execute every code cell in the notebook.
---@param bufnr integer
function M.run_all(bufnr)
  local s = get_state(bufnr)
  local cells = cell.get_cells(bufnr)
  if not s.job_id then
    utils.warn("No kernel running.")
    return
  end
  for _, cs in ipairs(cells) do
    if cs.cell_type == "code" then
      clear_cell_output(bufnr, cs)
      local mid = next_msg_id(bufnr)
      s.pending[mid] = { cell_state = cs, bufnr = bufnr, start_ms = vim.loop.now() }
      cell.update_status(bufnr, cs, "busy", nil)
      send(bufnr, { cmd = "execute", code = cell.get_cell_source(bufnr, cs), msg_id = mid })
    end
  end
end

--- Execute all code cells above the cursor.
---@param bufnr integer
function M.run_all_above(bufnr)
  local _, idx = cell.cell_at_cursor(bufnr)
  if not idx then
    return
  end
  local s = get_state(bufnr)
  if not s.job_id then
    utils.warn("No kernel running.")
    return
  end
  for _, entry in ipairs(cell.cells_above(bufnr, idx)) do
    local cs = entry.cell_state
    if cs.cell_type == "code" then
      clear_cell_output(bufnr, cs)
      local mid = next_msg_id(bufnr)
      s.pending[mid] = { cell_state = cs, bufnr = bufnr, start_ms = vim.loop.now() }
      cell.update_status(bufnr, cs, "busy", nil)
      send(bufnr, { cmd = "execute", code = cell.get_cell_source(bufnr, cs), msg_id = mid })
    end
  end
end

--- Execute all code cells from the cursor downwards.
---@param bufnr integer
function M.run_all_below(bufnr)
  local _, idx = cell.cell_at_cursor(bufnr)
  if not idx then
    return
  end
  local s = get_state(bufnr)
  local cells = cell.get_cells(bufnr)
  if not s.job_id then
    utils.warn("No kernel running.")
    return
  end
  for i = idx, #cells do
    local cs = cells[i]
    if cs.cell_type == "code" then
      clear_cell_output(bufnr, cs)
      local mid = next_msg_id(bufnr)
      s.pending[mid] = { cell_state = cs, bufnr = bufnr, start_ms = vim.loop.now() }
      cell.update_status(bufnr, cs, "busy", nil)
      send(bufnr, { cmd = "execute", code = cell.get_cell_source(bufnr, cs), msg_id = mid })
    end
  end
end

--- Request completions asynchronously. Calls cb(msg) when ready.
---@param bufnr integer
---@param code string
---@param cursor_pos integer
---@param cb function
function M.complete(bufnr, code, cursor_pos, cb)
  local s = get_state(bufnr)
  if not s.job_id then
    return
  end
  local mid = next_msg_id(bufnr)
  s.pending[mid] = cb
  send(bufnr, { cmd = "complete", code = code, cursor_pos = cursor_pos, msg_id = mid })
end

--- Request inline documentation asynchronously. Calls cb(msg) when ready.
---@param bufnr integer
---@param code string
---@param cursor_pos integer
---@param cb function
function M.inspect(bufnr, code, cursor_pos, cb)
  local s = get_state(bufnr)
  if not s.job_id then
    return
  end
  local mid = next_msg_id(bufnr)
  s.pending[mid] = cb
  send(bufnr, { cmd = "inspect", code = code, cursor_pos = cursor_pos, msg_id = mid })
end

--- Open a floating window showing kernel status.
---@param bufnr integer
function M.show_info(bufnr)
  local s = get_state(bufnr)
  local lines = {
    " Kernel Info ",
    string.rep("─", 34),
    "",
    "  Status  : " .. s.status,
    "  Kernel  : " .. (s.kernel_name ~= "" and s.kernel_name or "(none)"),
    "  Language: " .. (s.language ~= "" and s.language or "(unknown)"),
    "  Version : " .. (s.version ~= "" and s.version or "(unknown)"),
    "  Job ID  : " .. tostring(s.job_id or "—"),
    "",
    "  Press q or <Esc> to close.",
  }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  local width = 38
  local height = #lines
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " Jupyter Kernel ",
    title_pos = "center",
  })

  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function()
      vim.api.nvim_win_close(win, true)
    end, { buffer = buf, noremap = true, silent = true })
  end
end

--- Execute an arbitrary code snippet and deliver the combined stdout to cb.
--- Bypasses the cell output pipeline entirely - no extmarks are touched.
--- cb is called as cb(text, err) where text is the accumulated stdout string
--- and err is a string on failure or nil on success.
---@param bufnr integer
---@param code string
---@param cb function  called with (text: string|nil, err: string|nil)
function M.execute_snippet(bufnr, code, cb)
  local s = get_state(bufnr)
  if not s.job_id then
    cb(nil, "No kernel running.")
    return
  end
  local mid = next_msg_id(bufnr)
  s.pending[mid] = { _snippet_cb = cb, _accumulated = {} }
  send(bufnr, { cmd = "execute", code = code, msg_id = mid })
end

--- Return the kernel status for a buffer.
---@param bufnr integer
---@return string
function M.status(bufnr)
  return get_state(bufnr).status
end

--- Clean up kernel state when a buffer is deleted.
---@param bufnr integer
function M.on_buf_delete(bufnr)
  local s = _state[bufnr]
  if s and s.job_id then
    vim.fn.jobstop(s.job_id)
  end
  _state[bufnr] = nil
end

return M
