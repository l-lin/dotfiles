local java_configurer = require("plugins.custom.lang.java")
-- Fetch Java related libraries from another registry (main mason registry does not have the java-test, lombok and spring-boot-tools).
local mason_registries = { "github:nvim-java/mason-registry", "github:mason-org/mason-registry" }

return {
  recommended = function()
    return LazyVim.extras.wants({ ft = "java", root = java_configurer.root_markers })
  end,

  -- Disable neotest (supported by https://github.com/rcasia/neotest-java but less developer friendly)
  {
    "nvim-neotest/neotest",
    keys = {
      { "<M-S-F9>", false },
      { "<F21>", false },
    },
  },

  -- Add java to treesitter.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "java" } },
  },

  -- Debugger
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = {
          registries = mason_registries,
          ensure_installed = { "java-debug-adapter", "java-test" },
        },
      },
    },
  },

  -- Set up LSP
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- make sure mason installs the server
      servers = { jdtls = {} },
      setup = {
        jdtls = function()
          return true -- avoid duplicate servers
        end,
      },
    },
  },

  -- Set up nvim-jdtls
  {
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = {
          registries = mason_registries,
          ensure_installed = { "jdtls", "lombok-nightly" },
        },
      },
    },
    config = java_configurer.setup_jdtls,
  },
}
