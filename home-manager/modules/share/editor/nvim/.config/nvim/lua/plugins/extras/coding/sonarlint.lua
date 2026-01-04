return {
  -- linter
  {
    "sonarlint",
    url = "https://gitlab.com/schrieveslaach/sonarlint.nvim",
    ft = { "go", "js", "java", "xml" },
    opts = function()
      local jars = vim.fn.globpath("$MASON/share/sonarlint-language-server", "*.jar", true, true)
      return {
        server = {
          cmd = {
            "sonarlint-language-server",
            -- Ensure that sonarlint-language-server uses stdio channel
            "-stdio",
            "-analyzers",
            jars
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
