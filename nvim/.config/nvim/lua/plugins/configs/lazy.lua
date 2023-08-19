local M = {}

local function change_highlights()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "lazy",
    callback = function()
      vim.api.nvim_set_hl(0, "LazyNormal", { bg = "none" })
      vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
    end
  })
end

local function create_config()
  return {
    -- defaults = { lazy = true },
    install = { colorscheme = { "kanagawa" } },

    ui = {
      border = "rounded",
      icons = {
        ft = "",
        lazy = "󰂠 ",
        loaded = "",
        not_loaded = "",
      },
    },

    performance = {
      rtp = {
        disabled_plugins = {
          "2html_plugin",
          "tohtml",
          "getscript",
          "getscriptPlugin",
          "gzip",
          "logipat",
          "netrw",
          "netrwPlugin",
          "netrwSettings",
          "netrwFileHandlers",
          "matchit",
          "tar",
          "tarPlugin",
          "rrhelper",
          "spellfile_plugin",
          "vimball",
          "vimballPlugin",
          "zip",
          "zipPlugin",
          "tutor",
          "rplugin",
          "syntax",
          "synmenu",
          "optwin",
          "compiler",
          "bugreport",
          "ftplugin",
        },
      },
    },
  }
end

M.setup = function(plugins)
  require("lazy").setup(plugins, create_config())
  change_highlights()
end

return M
