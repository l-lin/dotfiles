local function setup()
  local mason_registry = require("mason-registry")
  if not mason_registry.has_package("java-debug-adapter") then
    return
  end

  -- Custom init for Java debugger.
  require("jdtls").setup_dap({ hotcodereplace = "auto", config_overrides = {} })
  require("jdtls.dap").setup_dap_main_class_configs()
  -- Setup dap config by VsCode launch.json file.
  require("dap.ext.vscode").load_launchjs()
end

-- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation.
local function create_bundles()
  local mason_registry = require("mason-registry")
  if not mason_registry.has_package("java-debug-adapter") then
    return
  end

  local bundles = {}
  -- jdtls tools configuration for debugging support
  local jar_patterns = vim.fn.globpath("$MASON/share/java-debug-adapter", "*.jar", true, true)
  for _, jar_pattern in ipairs(jar_patterns) do
    for _, bundle in ipairs(vim.split(vim.fn.glob(jar_pattern), "\n")) do
      table.insert(bundles, bundle)
    end
  end
  return bundles
end

local M = {}
M.setup = setup
M.create_bundles = create_bundles
return M
