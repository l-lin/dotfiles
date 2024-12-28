local function setup()
  local mason_registry = require("mason-registry")
  if not mason_registry.has_package("java-debug-adapter") then
    return
  end

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function()
      -- custom init for Java debugger
      require("jdtls").setup_dap({ hotcodereplace = "auto", config_overrides = {} })
      require("jdtls.dap").setup_dap_main_class_configs()
      -- setup dap config by VsCode launch.json file
      require("dap.ext.vscode").load_launchjs()
    end,
  })
end

local M = {}
M.setup = setup
return M
