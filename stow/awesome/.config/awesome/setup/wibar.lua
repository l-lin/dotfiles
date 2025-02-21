local awful = require("awful")
local widgets = require("lib.widgets")
local wibox = require("wibox")

local function setup(s)
  s.mytaglist = awful.widget.taglist({
    screen = s,
    filter = awful.widget.taglist.filter.all,
    buttons = widgets.taglist,
  })

  s.mywibox = awful.wibar({ position = "top", screen = s })
  s.mywibox:setup({
    layout = wibox.layout.align.horizontal,
    expand = "none",
    -- Left widgets
    {
      layout = wibox.layout.fixed.horizontal,
      s.mypromptbox,
      s.mytaglist,
      widgets.download_speed.widget,
      widgets.upload_speed.widget,
    },
    -- Middle widgets
    {
      layout = wibox.layout.flex.horizontal,
      widgets.systray,
    },
    -- Right widgets
    {
      layout = wibox.layout.fixed.horizontal,
      widgets.volume.widget,
      widgets.mem.widget,
      widgets.cpu.widget,
      widgets.temperature.widget,
      wibox.widget.textclock(" 󰃭 %Y-%m-%d %H:%M "),
      widgets.bat.widget,
    },
  })
end

local M = {}
M.setup = setup
return M
