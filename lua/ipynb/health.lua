--- ipynb.health
--- :checkhealth ipynb  - diagnose plugin setup issues.

local M = {}

local function check_nvim_version()
  vim.health.start("Neovim version")
  if vim.fn.has("nvim-0.9") == 1 then
    vim.health.ok("nvim >= 0.9")
  else
    vim.health.error("nvim >= 0.9 is required")
  end
end

local function check_python()
  vim.health.start("Python runtime")
  local out = vim.fn.system("python3 --version 2>&1")
  local ver = out:match("Python (%d+%.%d+)")
  if not ver then
    vim.health.error("python3 not found in PATH", { "Install Python >= 3.12" })
    return
  end
  local major, minor = ver:match("(%d+)%.(%d+)")
  if tonumber(major) >= 3 and tonumber(minor) >= 12 then
    vim.health.ok("python3 " .. ver)
  else
    vim.health.warn("python3 " .. ver .. " found; >= 3.12 recommended")
  end
end

local function check_uv()
  vim.health.start("uv package manager")
  local out = vim.fn.system("uv --version 2>&1")
  if vim.v.shell_error == 0 then
    vim.health.ok(out:gsub("%s+$", ""))
  else
    vim.health.error("uv not found", {
      "Install uv: https://docs.astral.sh/uv/getting-started/installation/",
    })
  end
end

local function check_kernel_bridge()
  vim.health.start("Kernel bridge dependencies")
  -- Locate python/ directory relative to this file.
  local src = debug.getinfo(1, "S").source:sub(2)
  local plugin_root = src:match("^(.*)/lua/ipynb/health%.lua$")
  if not plugin_root then
    vim.health.warn("Could not locate plugin root - skipping kernel bridge check")
    return
  end
  local python_dir = plugin_root .. "/python"
  if vim.fn.isdirectory(python_dir) == 0 then
    vim.health.error("python/ directory not found at " .. python_dir)
    return
  end
  -- Check that zmq and jupyter_client are importable (installed via uv sync).
  local check_cmd = string.format(
    "cd %s && uv run python3 -c 'import zmq, jupyter_client' 2>&1",
    vim.fn.shellescape(python_dir)
  )
  vim.fn.system(check_cmd)
  if vim.v.shell_error == 0 then
    vim.health.ok("zmq and jupyter_client available")
  else
    vim.health.error("kernel bridge deps missing", {
      "Run: uv sync --project " .. python_dir,
    })
  end
end

local function check_snacks_image()
  vim.health.start("snacks.nvim image backend")

  local ok_p, _ = pcall(require, "snacks.image.placement")
  if not ok_p then
    vim.health.error("snacks.nvim not found or image module not loaded", {
      "Install folke/snacks.nvim and enable the image module:",
      "require('snacks').setup({ image = { enabled = true } })",
    })
    return
  end
  vim.health.ok("snacks.nvim image module available")

  local ok_t, terminal = pcall(require, "snacks.image.terminal")
  if not ok_t then
    vim.health.error("snacks.image.terminal module unavailable")
    return
  end

  local ok_e, env = pcall(function()
    return terminal.env()
  end)
  if not ok_e or not env then
    vim.health.warn("Could not query terminal capabilities")
    return
  end

  if env.placeholders then
    vim.health.ok("Terminal supports Kitty unicode placeholders")
  else
    vim.health.error("Terminal does NOT support Kitty unicode placeholders", {
      "Use kitty 0.28+, Ghostty, or WezTerm",
      "Inside tmux: ensure pass_through is configured",
    })
  end

  if env.kitty then
    vim.health.ok("Kitty graphics protocol detected")
  else
    vim.health.warn("Kitty graphics protocol not detected by snacks")
  end
end

local function check_lsp()
  vim.health.start("LSP (optional)")

  local ok_lsp = pcall(require, "lspconfig")
  if ok_lsp then
    vim.health.ok("nvim-lspconfig found")
  else
    vim.health.warn("nvim-lspconfig not found", {
      "Install neovim/nvim-lspconfig for LSP completion and diagnostics",
    })
  end

  -- Check for a running Python LSP client.
  local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients
  local python_lsps = {}
  for _, client in ipairs(get_clients()) do
    local fts = (client.config or {}).filetypes or {}
    for _, ft in ipairs(fts) do
      if ft == "python" then
        python_lsps[#python_lsps + 1] = client.name
        break
      end
    end
  end
  if #python_lsps > 0 then
    vim.health.ok("Python LSP running: " .. table.concat(python_lsps, ", "))
  else
    vim.health.warn("No Python LSP client running", {
      "Start a .py file first, or configure pyright / pylsp to auto-start",
    })
  end
end

local function check_optional_plugins()
  vim.health.start("Optional plugins")

  if pcall(require, "nvim-web-devicons") then
    vim.health.ok("nvim-web-devicons found (language icons in cell borders)")
  else
    vim.health.info("nvim-web-devicons not found - language icons disabled")
  end

  if pcall(require, "nvim-treesitter") then
    vim.health.ok("nvim-treesitter found")
  else
    vim.health.info("nvim-treesitter not found - syntax highlighting limited")
  end

  if pcall(require, "cmp") then
    vim.health.ok("nvim-cmp found (kernel completion source active)")
  else
    vim.health.info("nvim-cmp not found - omnifunc completion only")
  end
end

function M.check()
  check_nvim_version()
  check_python()
  check_uv()
  check_kernel_bridge()
  check_snacks_image()
  check_lsp()
  check_optional_plugins()
end

return M
