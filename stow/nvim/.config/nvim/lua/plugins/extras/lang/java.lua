local java_configurer = require("plugins.custom.lang.java")
-- Fetch Java related libraries from another registry (main mason registry does not have the java-test, lombok and spring-boot-tools).
-- To install a specific version of a package installed by Mason:
-- 1. edit .local/share/nvim/mason/registries/github/mason-org/mason-registry/registry.json
-- 2. uninstall the LSP/DAP/Whatever from Mason UI
-- 3. search for your LSP/DAP/Whatever and put your version
-- 4. re-open Neovim
-- src: https://github.com/rochakgupta/dotfiles/blob/e68d52d5b33b9d93e13ca8db8c63c04745cdd995/.config/nvim/lua/rochakgupta/plugins/nvim-lspconfig/servers.lua#L5-L20
local mason_registries = { "github:nvim-java/mason-registry", "github:mason-org/mason-registry" }

return {
  recommended = function()
    return LazyVim.extras.wants({
      ft = "java",
      root = java_configurer.root_markers,
    })
  end,

  -- Disable neotest (supported by https://github.com/rcasia/neotest-java but less developer friendly)
  {
    "nvim-neotest/neotest",
    optional = true,
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
    config = java_configurer.jdtls_config,
  },
}
