local lain = require("lain")
local wibox = require("wibox")
local naughty = require("naughty")

-- Global variables that are set by Lain.
_G.bat_now = bat_now
_G.coretemp_now = coretemp_now
_G.load_1 = load_1
_G.mem_now = mem_now
_G.volume_now = volume_now

local markup = lain.util.markup
local net = require("lib.net")

local theme = require("theme")

local function download_speed()
  return net({
    settings = function ()
      widget:set_markup("󰅢  " .. net_now.received .. "K/s")
    end
  })
end

local function upload_speed()
  return net({
    settings = function ()
      widget:set_markup("󰅧  " .. net_now.sent .. "K/s")
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

      widget:set_markup(icon .. volume_now.level .. "%")
    end
  })
end

local function mem()
  return lain.widget.mem({
    settings = function()
      local display = " " .. mem_now.perc .. "%"
      if mem_now.perc > 80 then
        widget:set_markup(markup.fontfg(theme.font, theme.fg_urgent, display))
      elseif mem_now.perc > 50 then
        widget:set_markup(markup.fontfg(theme.font, theme.fg_warning, display))
      else
        widget:set_markup(markup.fontfg(theme.font, theme.fg_normal, display))
      end
    end
  })
end

local function cpu()
  return lain.widget.sysload({
    settings = function()
      local display = " " .. load_1

      local load_num = tonumber(load_1)
      if not load_num then
        widget:set_markup(markup.fontfg(theme.font, theme.fg_normal, display))
        return
      end

      if load_num > 6 then
        widget:set_markup(markup.fontfg(theme.font, theme.fg_urgent, display))
      elseif load_num > 4 then
        widget:set_markup(markup.fontfg(theme.font, theme.fg_warning, display))
      else
        widget:set_markup(markup.fontfg(theme.font, theme.fg_normal, display))
      end
    end
  })
end

local function temperature()
  return lain.widget.temp({
    settings = function()
      local display = " " .. coretemp_now .. "°"

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
      local display = icon .. bat_now.perc .. "%"

      widget:set_markup(display)
    end
  })
end

local function notification_status()
  local w = { widget = wibox.widget.textbox() }
  function w.update()
    if naughty.is_suspended() then
      w.widget:set_markup("󰂛 ")
    else
      w.widget:set_markup(markup.fontfg(theme.font, theme.fg_warning, "󰂞 "))
    end
  end
  w.update()

  return w
end

local function systray()
  local w = wibox.widget.systray()
  w:set_base_size(theme.systray_icon_base_size)

  local systray_with_padding = wibox.container.margin(w)
  systray_with_padding:set_top(theme.systray_margin_top)
  return systray_with_padding
end

local M = {}
M.download_speed = download_speed()
M.upload_speed = upload_speed()
M.notification_status = notification_status()
M.volume = volume()
M.mem = mem()
M.cpu = cpu()
M.temperature = temperature()
M.bat = bat()
M.systray = systray()
return M
