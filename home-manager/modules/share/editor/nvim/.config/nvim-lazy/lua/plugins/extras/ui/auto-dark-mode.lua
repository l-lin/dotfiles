---Reload the colorscheme on bg change.
---For some reason, I need to call it twice to have all the right
---colors, like in markdown or the TODO comments.
local function reload_colorscheme()
  vim.cmd("colorscheme " .. vim.g.colorscheme)
  vim.cmd("colorscheme " .. vim.g.colorscheme)
end

return {
  {
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    opts = {
      set_dark_mode = reload_colorscheme,
      set_light_mode = reload_colorscheme,
      update_interval = 3000,
      fallback = "dark",
    },
  },
}
