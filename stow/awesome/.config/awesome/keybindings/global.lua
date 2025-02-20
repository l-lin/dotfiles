local awesome, client, root = awesome, client, root

local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")

local config = require("config")
local wibar = require("setup.wibar")

local function globalkeys()
  local widgets = require("lib.widgets")

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

    -- Screenshot
    awful.key({ config.modkey }, "s", function () awful.spawn("flameshot gui") end, { description = "take screenshot", group = "hotkeys" }),

    -- Notifications
    awful.key({ config.modkey }, "v", function() naughty.toggle() end, { description = "toggle notifications", group = "hotkeys" }),
    awful.key({ config.modkey, "Control" }, "v", function() naughty.destroy_all_notifications() end, { description = "destroy notifications", group = "hotkeys" }),

    -- TODO: is it useful?
    awful.key(
      { config.modkey }, "x",
      function()
        awful.prompt.run({
          prompt = "Run Lua code: ",
          textbox = awful.screen.focused().mypromptbox.widget,
          exe_callback = awful.util.eval,
          history_path = awful.util.get_cache_dir() .. "/history_eval",
        })
      end,
      { description = "lua execute prompt", group = "awesome" }
    ),

    -- Sound control
    -- Not sure I don't need to use the terminal here...
    awful.key({ config.modkey }, "a", function() awful.spawn("pulsemixer") end, { description = "open audio control", group = "hotkeys" }),
    awful.key({ config.modkey, "Shift" }, "m", function() awful.spawn(config.terminal .. " -e ncmpcpp --screen visualizer") end, { description = "open mpd visualizer", group = "hotkeys" }),
    awful.key({ config.modkey, "Shift" }, "n", function() awful.spawn("mpc -q next") end, { description = "next mpd song", group = "hotkeys" }),
    awful.key({ config.modkey, "Shift" }, "p", function() awful.spawn("mpc -q toggle") end, { description = "toggle mpd play/pause", group = "hotkeys" }),
    awful.key({ config.modkey }, "m", function() awful.spawn("spotify") end, { description = "open spotify", group = "hotkeys" }),
    awful.key({ config.modkey }, "n", function() awful.spawn("spotify-next") end, { description = "next spotify song", group = "hotkeys" }),
    awful.key({ config.modkey }, "p", function() awful.spawn("spotify-toggle") end, { description = "toggle spotify play/pause", group = "hotkeys" }),
    awful.key({ }, "XF86AudioRaiseVolume", function () awful.spawn.with_line_callback("pamixer -i 5", { exit = widgets.volume.update }) end, { description = "sound +5%", group = "hotkeys" }),
    awful.key({ }, "XF86AudioLowerVolume", function () awful.spawn.with_line_callback("pamixer -d 5", { exit = widgets.volume.update }) end, { description = "sound -5%", group = "hotkeys" }),
    awful.key({ }, "XF86AudioMute", function () awful.spawn.with_line_callback("pamixer -t", { exit = widgets.volume.update }) end, { description = "mute sound", group = "hotkeys" }),

    -- Applications
    awful.key({ config.modkey }, "w", function() awful.spawn("xscreensaver-command -lock") end, { description = "lockscreen", group = "tag" }),
    awful.key({ config.modkey }, "c", function() awful.spawn(config.terminal .. " -e numbat --intro-banner off") end, { description = "open calculator", group = "hotkeys" }),
    awful.key({ config.modkey, "Shift" }, "o", function() awful.spawn("gcolor3") end, { description = "open color picker", group = "hotkeys" })
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
