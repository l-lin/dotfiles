local client = client

local awful = require("awful")
local widgets = require("lib.widgets")
local wibox = require("wibox")
local gears = require("gears")

local theme = require("theme")
local config = require("config")

local function taglist_buttons()
  return gears.table.join(
    awful.button({}, 1, function(t)
      t:view_only()
    end),
    awful.button({ config.modkey }, 1, function(t)
      if client.focus then
        client.focus:move_to_tag(t)
      end
    end),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({ config.modkey }, 3, function(t)
      if client.focus then
        client.focus:toggle_tag(t)
      end
    end),
    awful.button({}, 4, function(t)
      awful.tag.viewnext(t.screen)
    end),
    awful.button({}, 5, function(t)
      awful.tag.viewprev(t.screen)
    end)
  )
end

local function taglist_widget(s)
  return awful.widget.taglist({
    screen = s,
    filter = awful.widget.taglist.filter.all,
    buttons = taglist_buttons(),
    widget_template = {
      widget = wibox.container.margin,
      top = theme.taglist_margin_top,
      bottom = theme.taglist_margin_bottom,
      {
        widget = wibox.container.background,
        id = "background_role",
        {
          widget = wibox.container.margin,
          left = theme.taglist_margin_left,
          right = theme.taglist_margin_right,
          { id = "text_role", widget = wibox.widget.textbox },
        },
      },
    },
  })
end

local function setup(s)
  local big_space = wibox.widget.textbox()
  big_space.forced_width = theme.big_space_width
  local space = wibox.widget.textbox(" ")

  s.mywibox = awful.wibar({ position = "top", screen = s })
  s.mywibox:setup({
    layout = wibox.layout.align.horizontal,
    expand = "none",
    -- Left widgets
    {
      layout = wibox.layout.fixed.horizontal,
      big_space,
      taglist_widget(s),
      space,
      widgets.download_speed.widget,
      space,
      widgets.upload_speed.widget,
      space,
      s.mypromptbox,
    },
    -- Middle widgets
    {
      layout = wibox.layout.flex.horizontal,
      widgets.systray,
    },
    -- Right widgets
    {
      layout = wibox.layout.fixed.horizontal,
      widgets.notification_status.widget,
      space,
      widgets.volume.widget,
      space,
      widgets.mem.widget,
      space,
      widgets.cpu.widget,
      space,
      widgets.temperature.widget,
      space,
      wibox.widget.textclock("󰃭 %Y-%m-%d %H:%M"),
      space,
      widgets.bat.widget,
      big_space,
    },
  })
end

local M = {}
M.setup = setup
return M
