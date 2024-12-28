-- custom keymaps for Java test runner (not yet compatible with neotest)
-- enable junit extension detection to activate https://github.com/laech/java-stacksrc
local jdtls_test_opts = {
  config_overrides = {
    vmArgs = "-Djunit.jupiter.extensions.autodetection.enabled=true --enable-preview",
  },
}

local function attach_keymaps()
  local mason_registry = require("mason-registry")
  if not mason_registry.has_package("java-test") then
    return
  end

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local jdtls = require("jdtls")
      local jdtls_test = require("jdtls.tests")

      vim.keymap.set("n", "<C-T>", jdtls_test.goto_subjects, { noremap = true, silent = true, desc = "Find associated test or class file (Ctrl+t)" })
      vim.keymap.set("n", "<M-S-F9>", function()
        jdtls.pick_test(jdtls_test_opts)
      end, { noremap = true, silent = true, desc = "Run specific test (Alt+Shift+F9)" })

      vim.keymap.set("n", "<F21>", function()
        jdtls.test_nearest_method(jdtls_test_opts)
      end, { noremap = true, silent = true, desc = "Test method (Shift+F9)" })

      local wk = require("which-key")
      wk.add({
        {
          mode = "n",
          buffer = args.buf,
          { "<leader>t", group = "test" },
          { "<leader>tt", function() jdtls.test_class(jdtls_test_opts) end, desc = "Run All Test" },
          { "<leader>tr", function() jdtls.test_nearest_method(jdtls_test_opts) end, desc = "Run nearest test (Shift+F9)" },
          { "<leader>tT", function() jdtls.pick_test(jdtls_test_opts) end, desc = "Run specific test (Alt+Shift+F9)" },
        },
      })
    end,
  })
end

-- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
local function create_bundles()
  -- lookup paths for java test and debugger package
  local mason_registry = require("mason-registry")
  local bundles = {}
  if mason_registry.has_package("java-test") and mason_registry.has_package("java-debug-adapter") then
    -- jdtls tools configuration for debugging support
    local java_debug_adapter_pkg = mason_registry.get_package("java-debug-adapter")
    local java_debug_adapter_path = java_debug_adapter_pkg:get_install_path()
    local java_test_pkg = mason_registry.get_package("java-test")
    local java_test_path = java_test_pkg:get_install_path()
    local jar_patterns = {
      java_debug_adapter_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar",
      java_test_path .. "/extension/server/*.jar",
    }
    for _, jar_pattern in ipairs(jar_patterns) do
      for _, bundle in ipairs(vim.split(vim.fn.glob(jar_pattern), "\n")) do
        if
          not vim.endswith(bundle, "com.microsoft.java.test.runner-jar-with-dependencies.jar")
          and not vim.endswith(bundle, "com.microsoft.java.test.runner.jar")
        then
          table.insert(bundles, bundle)
        end
      end
    end
  end
  return bundles
end

local M = {}
M.attach_keymaps = attach_keymaps
M.create_bundles = create_bundles
return M
