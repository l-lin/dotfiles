local awful = require("awful")
local config = require("config")

awful.screen.connect_for_each_screen(function(s)
  -- Each screen has its own tag table.
  awful.tag(config.tags, s, awful.layout.layouts[1])

  -- Create a promptbox for each screen
  s.mypromptbox = awful.widget.prompt()

  -- Setup wibar
  require("setup.wibar").setup(s)
end)
