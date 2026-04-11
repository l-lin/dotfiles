---@type vim.pack.Spec
return
-- linter
{
  src = "https://gitlab.com/schrieveslaach/sonarlint.nvim",
  data = {
    setup = function()
      local jars = vim.fn.globpath("$MASON/share/sonarlint-language-server", "*.jar", true, true)
      require("sonarlint").setup({
        server = {
          cmd = {
            "sonarlint-language-server",
            -- Ensure that sonarlint-language-server uses stdio channel
            "-stdio",
            "-analyzers",
            jars,
          },
        },
        filetypes = {
          "go",
          "java",
          "js",
          "xml",
        },
      })
    end,
  },
}
