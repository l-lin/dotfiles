-- Custom keymaps for Java test runner (not yet compatible with neotest).
-- Enable junit extension detection to activate https://github.com/laech/java-stacksrc.
local jdtls_test_opts = {
  config_overrides = {
    vmArgs = "-Djunit.jupiter.extensions.autodetection.enabled=true --enable-preview",
  },
}

local function attach_keymaps(bufnr)
  local mason_registry = require("mason-registry")
  if not mason_registry.has_package("java-test") then
    return
  end

  local jdtls = require("jdtls")
  local jdtls_test = require("jdtls.tests")

  -- vim.keymap.set("n", "<C-T>", jdtls_test.goto_subjects, { buffer = bufnr, noremap = true, silent = true, desc = "Find associated test or class file (Ctrl+t)" })
  vim.keymap.set("n", "<M-S-F9>", function()
    jdtls.pick_test(jdtls_test_opts)
  end, { buffer = bufnr, noremap = true, silent = true, desc = "Run specific test (Alt+Shift+F9)" })

  vim.keymap.set("n", "<F21>", function()
    jdtls.test_nearest_method(jdtls_test_opts)
  end, { buffer = bufnr, noremap = true, silent = true, desc = "Test method (Shift+F9)" })

  local wk = require("which-key")
  wk.add({
    {
      mode = "n",
      buffer = bufnr,
      { "<leader>t", group = "test" },
      { "<leader>ta", function() jdtls.test_class(jdtls_test_opts) end, desc = "Run All Test" },
      { "<leader>tg", jdtls_test.generate, desc = "Generate test" },
      { "<leader>tn", function() jdtls.test_nearest_method(jdtls_test_opts) end, desc = "Run nearest test (Shift+F9)" },
      { "<leader>ts", function() jdtls.pick_test(jdtls_test_opts) end, desc = "Run specific test (Alt+Shift+F9)" },
      { "gS", require("jdtls.tests").goto_subjects, desc = "Goto Subjects" },
    },
  })
end

-- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
local function create_bundles()
  local mason_registry = require("mason-registry")
  if not mason_registry.has_package("java-test") then
    return
  end
  local java_test_pkg = mason_registry.get_package("java-test")

  local bundles = {}
  local java_test_path = java_test_pkg:get_install_path()
  local jar_patterns = {
    java_test_path .. "/extension/server/*.jar",
  }
  for _, jar_pattern in ipairs(jar_patterns) do
    for _, bundle in ipairs(vim.split(vim.fn.glob(jar_pattern), "\n")) do
      table.insert(bundles, bundle)
    end
  end
  return bundles
end

local M = {}
M.attach_keymaps = attach_keymaps
M.create_bundles = create_bundles
return M
