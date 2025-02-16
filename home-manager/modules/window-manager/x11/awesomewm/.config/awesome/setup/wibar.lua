local client = client

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")

local lain = require("lain")

local config = require("config")

local function taglist()
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

local function volume()
  return lain.widget.alsa({
    settings = function()
      local header = " Vol "
      local vlevel  = volume_now.level

      if volume_now.status == "off" then
          vlevel = vlevel .. "M "
      else
          vlevel = vlevel .. " "
      end

      widget:set_markup(header .. vlevel .. "% | ")
    end
  }).widget
end

local function mem()
  return lain.widget.mem({
    settings = function()
        widget:set_markup("RAM " .. mem_now.used .. "MB | ")
    end
  }).widget
end

-- TODO: change in percentage
local function cpu()
  return lain.widget.sysload({
    settings = function()
      widget:set_markup("CPU " .. load_1 .. " | ")
    end
  }).widget
end

local function bat()
  return lain.widget.bat({
    settings = function()
      local perc = bat_now.perc
      if bat_now.ac_status == 1 then
        perc = perc .. " "
      end
      widget:set_markup(" | BAT " .. perc .. " ")
    end
  }).widget
end

local function setup(s)
  s.mytaglist = awful.widget.taglist({
    screen = s,
    filter = awful.widget.taglist.filter.all,
    buttons = taglist(),
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
    },
    -- Middle widgets
    {
      layout = wibox.layout.flex.horizontal,
      wibox.widget.systray(),
    },
    -- Right widgets
    {
      layout = wibox.layout.fixed.horizontal,
      volume(),
      mem(),
      cpu(),
      wibox.widget.textclock("%Y-%m-%d %H:%M"),
      bat(),
    },
  })
end

local M = {}
M.setup = setup
return M
