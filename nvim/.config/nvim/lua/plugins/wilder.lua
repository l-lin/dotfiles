local M = {}

M.setup = function()
  local config = {
    modes = { ":", "/", "?" },
    next_key = "<C-n>",
    previous_key = "<C-p>",
    accept_key = "<Tab>"
  }

  local wilder = require("wilder")
  wilder.setup(config)
  wilder.set_option("renderer", wilder.popupmenu_renderer({
    highlighter = wilder.basic_highlighter(),
    left = { " ", wilder.popupmenu_devicons() },
    right = { " ", wilder.popupmenu_scrollbar() },
  }))
end

return M
