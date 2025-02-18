local client = client

local awful = require("awful")
local gears = require("gears")

local config = require("config")

local function keys()
	return gears.table.join(
		awful.key({ config.modkey }, "f", function(c)
			c.fullscreen = not c.fullscreen
			c:raise()
		end, { description = "toggle fullscreen", group = "client" }),
		awful.key({ config.modkey }, "q", function(c) c:kill() end, { description = "close", group = "client" }),
		awful.key(
      { config.modkey, "Shift" }, "q",
      function(c)
        if c.pid then
          awful.spawn("kill -9 " .. c.pid)
        end
      end,
      { description = "force close", group = "client" }
    ),
		awful.key({ config.modkey, "Control" }, "space", awful.client.floating.toggle, { description = "toggle floating", group = "client" }),
		awful.key({ config.modkey, "Control" }, "Return", function(c) c:swap(awful.client.getmaster()) end, { description = "move to master", group = "client" }),
		awful.key({ config.modkey }, "o", function(c) c:move_to_screen() end, { description = "move to screen", group = "client" }),
		awful.key({ config.modkey }, "t", function(c) c.ontop = not c.ontop end, { description = "toggle keep on top", group = "client" })
	)
end

local function buttons()
	return gears.table.join(
		awful.button({}, 1, function(c)
			c:emit_signal("request::activate", "mouse_click", { raise = true })
		end),
		awful.button({ config.modkey }, 1, function(c)
			c:emit_signal("request::activate", "mouse_click", { raise = true })
			awful.mouse.client.move(c)
		end),
		awful.button({ config.modkey }, 3, function(c)
			c:emit_signal("request::activate", "mouse_click", { raise = true })
			awful.mouse.client.resize(c)
		end)
	)
end

local function globalkeys()
  return gears.table.join(
		awful.key({ config.modkey }, "h", function() awful.client.focus.bydirection("left") end, { description = "swap to left client", group = "client" }),
		awful.key({ config.modkey }, "j", function() awful.client.focus.bydirection("down") end, { description = "swap to bottom client", group = "client" }),
		awful.key({ config.modkey }, "k", function() awful.client.focus.bydirection("up") end, { description = "swap to top client", group = "client" }),
		awful.key({ config.modkey }, "l", function() awful.client.focus.bydirection("right") end, { description = "swap to right client", group = "client" }),
		awful.key({ config.modkey, "Shift" }, "h", function() awful.client.swap.bydirection("left") end, { description = "swap to left client", group = "client" }),
		awful.key({ config.modkey, "Shift" }, "j", function() awful.client.swap.bydirection("down") end, { description = "swap to bottom client", group = "client" }),
		awful.key({ config.modkey, "Shift" }, "k", function() awful.client.swap.bydirection("up") end, { description = "swap to top client", group = "client" }),
		awful.key({ config.modkey, "Shift" }, "l", function() awful.client.swap.bydirection("right") end, { description = "swap to right client", group = "client" }),
		awful.key({ config.modkey }, "Tab", function()
			awful.client.focus.history.previous()
			if client.focus then
				client.focus:raise()
			end
		end, { description = "go back", group = "client" })
  )
end

local M = {}
M.keys = keys
M.buttons = buttons
M.globalkeys = globalkeys
return M
