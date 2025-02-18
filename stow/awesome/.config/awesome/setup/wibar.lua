local client = client

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")

local lain = require("lain")
local markup = lain.util.markup
local theme = require("theme.default")
local net = require("lib.net")

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

local function download_speed()
  return net({
    settings = function ()
      widget:set_markup(" 󰅢  " .. net_now.received .. "K/s ")
    end
  })
end

local function upload_speed()
  return net({
    settings = function ()
      widget:set_markup(" 󰅧  " .. net_now.sent .. "K/s ")
    end
  })
end

local function volume()
  return lain.widget.alsa({
    settings = function()
      local icon = ""
      if volume_now.status == "off" then
        icon = " "
      else
        if volume_now.level > 50 then
          icon = "  "
        elseif volume_now.level > 30 then
          icon = " "
        elseif volume_now.level > 15 then
          icon = " "
        end
      end

      widget:set_markup(icon .. volume_now.level .. "% ")
    end
  }).widget
end

local function mem()
  return lain.widget.mem({
    settings = function()
      local display = "   " .. mem_now.perc .. "% "
      if mem_now.perc > 80 then
        widget:set_markup(markup.fontfg(theme.font, theme.fg_urgent, display))
      elseif mem_now.perc > 50 then
        widget:set_markup(markup.fontfg(theme.font, theme.fg_warning, display))
      else
        widget:set_markup(markup.fontfg(theme.font, theme.fg_normal, display))
      end
    end
  }).widget
end

local function cpu()
  return lain.widget.sysload({
    settings = function()
      local display = "   " .. load_1

      local load_num = tonumber(load_1)
      if not load_num then
        widget:set_markup(markup.fontfg(theme.font, theme.fg_normal, display))
        return
      end

      if load_num > 13 then
        widget:set_markup(markup.fontfg(theme.font, theme.fg_urgent, display))
      elseif load_num > 8 then
        widget:set_markup(markup.fontfg(theme.font, theme.fg_warning, display))
      else
        widget:set_markup(markup.fontfg(theme.font, theme.fg_normal, display))
      end
    end
  }).widget
end

local function temperature()
  return lain.widget.temp({
    settings = function()
      local display = "  " .. coretemp_now .. "°C "

      local temp_num = tonumber(coretemp_now)
      if not temp_num then
        widget:set_markup(markup.fontfg(theme.font, theme.fg_normal, display))
        return
      end

      if temp_num > 90 then
        widget:set_markup(markup.fontfg(theme.font, theme.fg_urgent, display))
      elseif temp_num > 80 then
        widget:set_markup(markup.fontfg(theme.font, theme.fg_warning, display))
      else
        widget:set_markup(markup.fontfg(theme.font, theme.fg_normal, display))
      end
    end
  })
end

local function bat()
  return lain.widget.bat({
    settings = function()
      if (not bat_now.status) or bat_now.status == "N/A" or type(bat_now.perc) ~= "number" then
        return
      end

      local icon = ""
      if bat_now.perc > 90 then
        icon = " "
      elseif bat_now.perc > 70 then
        icon = " "
      elseif bat_now.perc > 50 then
        icon = " "
      elseif bat_now.perc > 30 then
        icon = " "
      elseif bat_now.perc > 15 then
        icon = " "
      end

      if bat_now.status == "Charging" then
        icon = " " .. icon
      end
      local display = icon .. bat_now.perc .. "% "

      widget:set_markup(display)
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
      download_speed(),
      upload_speed(),
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
      temperature(),
      wibox.widget.textclock(" 󰃭 %Y-%m-%d %H:%M "),
      bat(),
    },
  })
end

local M = {}
M.setup = setup
return M
