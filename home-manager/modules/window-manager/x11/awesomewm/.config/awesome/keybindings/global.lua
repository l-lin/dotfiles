local awesome, client, root = awesome, client, root

local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")

local config = require("config")

local function globalkeys()
	local keys = gears.table.join(
    -- awesome
		awful.key({ config.modkey, "Shift" }, "s", require("awful.hotkeys_popup").show_help, { description = "show help", group = "awesome" }),
		awful.key({ config.modkey, "Control" }, "r", awesome.restart, { description = "reload awesome", group = "awesome" }),
		--awful.key({ config.modkey, "Control" }, "q", awesome.quit, { description = "quit awesome", group = "awesome" }),

    -- Tags
		awful.key({ config.modkey }, "Left", awful.tag.viewprev, { description = "view previous", group = "tag" }),
		awful.key({ config.modkey }, "Right", awful.tag.viewnext, { description = "view next", group = "tag" }),
		awful.key({ config.modkey }, "Escape", awful.tag.history.restore, { description = "go back", group = "tag" }),

		-- Layout
		awful.key({ config.modkey, "Control" }, "Left", function() awful.tag.incmwfact(-0.05) end, { description = "decrease width factor", group = "layout" }),
		awful.key({ config.modkey, "Control" }, "Down", function() awful.client.incwfact(-0.1) end, { description = "decrease height factor", group = "layout" }),
		awful.key({ config.modkey, "Control" }, "Up", function() awful.client.incwfact(0.1) end, { description = "increase height factor", group = "layout" }),
		awful.key({ config.modkey, "Control" }, "Right", function() awful.tag.incmwfact(0.05) end, { description = "increase width factor", group = "layout" }),

		-- Standard program
		awful.key({ config.modkey }, "t", function() awful.spawn(config.terminal .. " -e tmux -2 -u") end, { description = "open a terminal", group = "launcher" }),
		awful.key({ config.modkey }, "a", function() awful.spawn(config.terminal .. " -e pulsemixer") end, { description = "audio mix", group = "launcher" }),
		awful.key({ config.modkey }, "e", function() awful.spawn(config.terminal .. " -e yazi") end, { description = "file manager", group = "launcher" }),
		awful.key({ config.modkey, "Shift" }, "e", function() awful.spawn("nautilus") end, { description = "file manager", group = "launcher" }),

		-- Prompt
		awful.key({ config.modkey }, "r", function() awful.screen.focused().mypromptbox:run() end, { description = "run prompt", group = "launcher" }),
    awful.key({ config.modkey }, "space", function() require("menubar").show() end, { description = "show the menubar", group = "launcher" }),

    -- Screen brightness
    awful.key({ }, "XF86MonBrightnessUp", function () awful.spawn("brightnessctl set +10%") end, { description = "Brightness +10%", group = "hotkeys" }),
    awful.key({ }, "XF86MonBrightnessDown", function () awful.spawn("brightnessctl set 10%-") end, { description = "Brightness -10%", group = "hotkeys" }),

    -- Sound control
    awful.key(
      { }, "XF86AudioRaiseVolume",
      function ()
        awful.spawn("pamixer -i 5")
        beautiful.volume.update()
      end,
      { description = "sound +5%", group = "hotkeys" }
    ),
    awful.key(
      { }, "XF86AudioLowerVolume",
      function ()
        awful.spawn("pamixer -d 5")
        beautiful.volume.update()
      end,
      { description = "sound -5%", group = "hotkeys" }
    ),
    awful.key(
      { }, "XF86AudioMute",
      function ()
        awful.spawn("pamixer -t")
        beautiful.volume.update()
      end,
      { description = "mute sound", group = "hotkeys" }
    )

    -- Applications
    -- TODO: LOCK
		-- awful.key({ constants.modkey }, "w", function() awful.spawn{ "xlock" } end, { description = "lockscreen", group = "tag" }),

    -- Widgets
    -- awful.key(
    --   { constants.modkey }, "c",
    --   function()
    --     if beautiful.cal then
    --       beautiful.cal.show(7)
    --     end
    --   end,
    --   { description = "show calendar", group = "widgets" }
    -- ),
    -- awful.key(
    --   { constants.modkey }, "e",
    --   function()
    --     if beautiful.fs then
    --       beautiful.fs.show(7)
    --     end
    --   end,
    --   { description = "show filesystem", group = "widgets" }
    -- ),
    -- awful.key(
    --   { constants.modkey, "Shift" }, "w",
    --   function()
    --     if beautiful.weather then
    --       beautiful.weather.show(7)
    --     end
    --   end,
    --   { description = "show weather", group = "widgets" }
    -- ),

    -- TODO: is it useful?
		-- awful.key({ config.modkey }, "x", function()
		-- 	awful.prompt.run({
		-- 		prompt = "Run Lua code: ",
		-- 		textbox = awful.screen.focused().mypromptbox.widget,
		-- 		exe_callback = awful.util.eval,
		-- 		history_path = awful.util.get_cache_dir() .. "/history_eval",
		-- 	})
		-- end, { description = "lua execute prompt", group = "awesome" })
	)

	-- Bind all key numbers to tags.
	-- Be careful: we use keycodes to make it work on any keyboard layout.
	-- This should map on the top row of your keyboard, usually 1 to 9.
	for i = 1, 9 do
		keys = gears.table.join(
			keys,
			-- View tag only.
			awful.key({ config.modkey }, "#" .. i + 9, function()
				local screen = awful.screen.focused()
				local tag = screen.tags[i]
				if tag then
					tag:view_only()
				end
			end, { description = "view tag #" .. i, group = "tag" }),

			-- Move client to tag.
			awful.key({ config.modkey, "Shift" }, "#" .. i + 9, function()
				if client.focus then
					local tag = client.focus.screen.tags[i]
					if tag then
						client.focus:move_to_tag(tag)
            -- Follow screen to selected tag.
            tag:view_only()
					end
				end
			end, { description = "move focused client to tag #" .. i, group = "tag" })
		)
	end

  keys = gears.table.join(keys, require("keybindings.client").globalkeys())

  return keys
end

root.keys(globalkeys())
