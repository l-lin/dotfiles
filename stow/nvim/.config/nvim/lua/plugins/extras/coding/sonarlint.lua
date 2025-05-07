return {
  -- linter
  {
    "sonarlint",
    url = "https://gitlab.com/schrieveslaach/sonarlint.nvim",
    ft = { "go", "js", "java", "xml" },
    opts = function()
      local sonarlint_path = require("mason-registry").get_package("sonarlint-language-server"):get_install_path()
      return {
        server = {
          cmd = {
            "sonarlint-language-server",
            -- Ensure that sonarlint-language-server uses stdio channel
            "-stdio",
            "-analyzers",
            sonarlint_path .. "/extension/analyzers/sonargo.jar",
            sonarlint_path .. "/extension/analyzers/sonarjava.jar",
            sonarlint_path .. "/extension/analyzers/sonarjs.jar",
            sonarlint_path .. "/extension/analyzers/sonarxml.jar",
          },
        },
        filetypes = {
          "go",
          "java",
          "js",
          "xml",
        },
      }
    end,
  },

  -- LSP/DAP/Linter manager
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "sonarlint-language-server" },
    },
  },
}
