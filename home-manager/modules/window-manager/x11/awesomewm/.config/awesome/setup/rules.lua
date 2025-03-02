local awful = require("awful")
local beautiful = require("beautiful")
local client_keybindings = require("keybindings.client")

-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
  -- All clients will match this rule.
  {
    rule = {},
    properties = {
      border_width = beautiful.border_width,
      border_color = beautiful.border_normal,
      focus = awful.client.focus.filter,
      raise = true,
      keys = client_keybindings.keys(),
      buttons = client_keybindings.buttons(),
      screen = awful.screen.preferred,
      placement = awful.placement.no_overlap + awful.placement.no_offscreen,
    },
  },

  -- Floating clients.
  -- To find the instance/class/name/role, execute the following
  --   xprop | grep "WM_CLASS\|WM_NAME\|WM_WINDOW_ROLE"
  -- and click on the window to get the information.
  {
    properties = { floating = true },
    rule_any = {
      instance = {
        "DTA", -- Firefox addon DownThemAll.
        "copyq", -- Includes session name in class.
        "pinentry",
      },
      class = {
        "Arandr",
        "Blueman-manager",
        "Gpick",
        "Kruler",
        "MessageWin", -- kalarm.
        "Sxiv",
        "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
        "Wpa_gui",
        "veromix",
        "xtightvncviewer",
      },

      -- Note that the name property shown in xprop might be set slightly after creation of the client
      -- and the name shown there might not match defined rules here.
      name = {
        "Event Tester", -- xev.
      },
      role = {
        "AlarmWindow", -- Thunderbird's calendar.
        "ConfigManager", -- Thunderbird's about:config.
        "pop-up", -- e.g. Google Chrome's (detached) Developer Tools.
      },
    },
  },

  -- Pin application on specific tags.
  { rule = { class = "obsidian" }, properties = { tag = " " } },
  { rule = { class = "Zen" }, properties = { tag = " " } },
  { rule = { class = "Slack" }, properties = { tag = " " } },
  { rule = { class = "Spotify" }, properties = { tag = " " } },
}
