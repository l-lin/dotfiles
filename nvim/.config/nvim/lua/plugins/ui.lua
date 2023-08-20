return {
  -- navigate between neovim and multiplexers
  {
    "numToStr/Navigator.nvim",
    keys = {
      { "<C-h>", "<cmd>NavigatorLeft<cr>", mode = { "n", "t" }, silent = true, desc = "Navigate left" },
      { "<C-l>", "<cmd>NavigatorRight<cr>", mode = { "n", "t" }, silent = true, desc = "Navigate right" },
      { "<C-k>", "<cmd>NavigatorUp<cr>", mode = { "n", "t" }, silent = true, desc = "Navigate up" },
      { "<C-j>", "<cmd>NavigatorDown<cr>", mode = { "n", "t" }, silent = true, desc = "Navigate down" },
    },
    cmd = { "NavigatorUp", "NavigatorDown", "NavigatorRight", "NavigatorLeft" },
    config = function()
      require("Navigator").setup({})
    end,
  },

  -- dashboard
  {
    "goolord/alpha-nvim",
    opts = function()
      local dashboard = require("alpha.themes.dashboard")
      local logo = [[]]

      dashboard.section.header.val = vim.split(logo, "\n")
      dashboard.section.buttons.val = {
        dashboard.button("f", " " .. " Find file", ":Telescope find_files <CR>"),
        dashboard.button("n", " " .. " New file", ":ene <BAR> startinsert <CR>"),
        dashboard.button("r", " " .. " Recent files", ":Telescope oldfiles <CR>"),
        dashboard.button("g", " " .. " Find text", ":Telescope live_grep <CR>"),
        dashboard.button("c", " " .. " Config", ":e $MYVIMRC <CR>"),
        dashboard.button("s", " " .. " Restore Session", [[:lua require("persistence").load() <cr>]]),
        dashboard.button("l", "󰒲 " .. " Lazy", ":Lazy<CR>"),
        dashboard.button("q", " " .. " Quit", ":qa<CR>"),
      }
      for _, button in ipairs(dashboard.section.buttons.val) do
        button.opts.hl = "AlphaButtons"
        button.opts.hl_shortcut = "AlphaShortcut"
      end
      dashboard.section.header.opts.hl = "AlphaHeader"
      dashboard.section.buttons.opts.hl = "AlphaButtons"
      dashboard.section.footer.opts.hl = "AlphaFooter"
      dashboard.opts.layout[1].val = 8
      return dashboard
    end,
  },
}
