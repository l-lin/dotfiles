local awesome, client = awesome, client

local awful = require("awful")
local beautiful = require("beautiful")

-- Autofocus on existing client when closing other clients.
-- Might be deprecated...
-- src: https://github.com/awesomeWM/awesome/blob/master/lib/awful/autofocus.lua
require("awful.autofocus")

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
  -- Set the windows at the slave,
  -- i.e. put it at the end of others instead of setting it master.
  -- if not awesome.startup then awful.client.setslave(c) end

  if awesome.startup
    and not c.size_hints.user_position
    and not c.size_hints.program_position then
    -- Prevent clients from being unreachable after screen count changes.
    awful.placement.no_offscreen(c)
  end
end)

-- No borders if only 1 client visible.
client.connect_signal("focus", function(c)
  if c.maximized then
    c.border_width = 0
  elseif #awful.screen.focused().clients > 1 then
    c.border_width = beautiful.border_width
    c.border_color = beautiful.border_focus
  end
end)
client.connect_signal("unfocus", function(c)
  c.border_color = beautiful.border_normal
end)

-- Issue with Firefox based browser where it only remembers its last state, and
-- stays maximized... So the other clients are not tiled along with the browser.
-- src: https://www.reddit.com/r/awesomewm/comments/wam8jg/deleted_by_user/
client.connect_signal("property::minimized", function(c)
  c.minimized = false
end)
client.connect_signal("property::maximized", function(c)
  c.maximized = false
end)
