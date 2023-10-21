return {
  {
    "nvim-neotest/neotest",
    keys = {
      {
        "<M-S-F9>",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Run File (Alt+Shift+F9)",
        noremap = true,
        silent = true,
      },
      {
        "<F21>",
        function()
          require("neotest").run.run()
        end,
        desc = "Run Nearest (Shift+F9)",
        noremap = true,
        silent = true,
      },
    },
  },
}
