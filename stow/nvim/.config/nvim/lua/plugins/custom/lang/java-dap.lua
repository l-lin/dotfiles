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
  local java_debug_adapter_pkg = mason_registry.get_package("java-debug-adapter")

  local bundles = {}
  -- jdtls tools configuration for debugging support
  local java_debug_adapter_path = java_debug_adapter_pkg:get_install_path()
  local jar_patterns = {
    java_debug_adapter_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar",
  }
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
