local awful = require("awful")
local config = require("config")

-- Set the terminal for applications that require it
require("menubar").utils.terminal = config.terminal

awful.screen.connect_for_each_screen(function(s)
  -- Each screen has its own tag table.
  local names = { " ", " ", " ", " ", " " }

  local layout = awful.layout.suit
  local layouts = { layout.tile, layout.tile, layout.tile, layout.tile, layout.tile }
  awful.tag(names, s, layouts)

  -- Create a promptbox for each screen
  s.mypromptbox = awful.widget.prompt()

  -- Setup wibar
  require("setup.wibar").setup(s)
end)
