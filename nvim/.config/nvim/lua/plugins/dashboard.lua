local M = {}

M.setup = function()
  local stats = require("lazy").stats()
  local config = {
    theme = "doom",
    config = {
      center = {
        {
          icon = "   ",
          icon_hl = "DashboardRecent",
          desc = "Recent Files                                    ",
          key = "r",
          key_hl = "DashboardRecent",
          action = "Telescope oldfiles",
        },
        {
          icon = "   ",
          icon_hl = "DashboardSession",
          desc = "Last Session",
          key = "s",
          key_hl = "DashboardSession",
          action = "lua require('persistence').load({last = true})",
        },
        {
          icon = "   ",
          icon_hl = "DashboardProject",
          desc = "Find Project",
          key = "p",
          key_hl = "DashboardProject",
          action = "Telescope projects",
        },
        {
          icon = "   ",
          icon_hl = "DashboardConfiguration",
          desc = "Configuration",
          key = "i",
          key_hl = "DashboardConfiguration",
          action = "Telescope find_files cwd=$HOME/perso/dotfiles/nvim/.config/nvim/",
        },
        {
          icon = "󰤄   ",
          icon_hl = "DashboardLazy",
          desc = "Lazy",
          key = "l",
          key_hl = "DashboardLazy",
          action = "Lazy",
        },
        {
          icon = "   ",
          icon_hl = "DashboardServer",
          desc = "Mason",
          key = "m",
          key_hl = "DashboardServer",
          action = "Mason",
        },
        {
          icon = "   ",
          icon_hl = "DashboardQuit",
          desc = "Quit Neovim",
          key = "q",
          key_hl = "DashboardQuit",
          action = "qa",
        },
      },
      footer = {
        "⚡ Neovim loaded " .. stats.count .. " plugins",
      },
    },
  }
  require("dashboard").setup(config)
end

return M
