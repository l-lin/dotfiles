local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Configures whether the window has a title bar and/or resizable border.
-- The value is a set of flags:
-- - window_decorations = "NONE" - disables titlebar and border (borderless mode), but causes problems with resizing and minimizing the window, so you probably want to use RESIZE instead of NONE if you just want to remove the title bar.
-- - window_decorations = "TITLE" - disable the resizable border and enable only the title bar
-- - window_decorations = "RESIZE" - disable the title bar but enable the resizable border
-- - window_decorations = "TITLE | RESIZE" - Enable titlebar and border. This is the default.
-- src: https://wezfurlong.org/wezterm/config/lua/config/window_decorations.html?h=window_de#window_decorations-title-resize
config.window_decorations = "NONE"

-- If set to true, when there is only a single tab, the tab bar is hidden from
-- the display. If a second tab is created, the tab will be shown.
-- src: https://wezfurlong.org/wezterm/config/lua/config/hide_tab_bar_if_only_one_tab.html#hide_tab_bar_if_only_one_tab-false
config.hide_tab_bar_if_only_one_tab = true

-- Setting the TERM so that the colors are well displayed with Tmux and Fzf (and
-- other tools).
-- src: https://wezfurlong.org/wezterm/config/lua/config/term.html?h=terminfo#term-xterm-256color
config.set_environment_variables = {
  -- The terminfo is provided from the wezterm nix package.
  -- src: https://github.com/NixOS/nixpkgs/blob/5df43628fdf08d642be8ba5b3625a6c70731c19c/pkgs/by-name/we/wezterm/package.nix#L129-L137
  TERMINFO_DIRS = os.getenv("HOME") .. "/.nix-profile/share/terminfo",
}
config.term = "wezterm"

-- Control whether changing the font size adjusts the dimensions of the window
-- (true) or adjusts the number of terminal rows/columns (false). The default is
-- true. If you use a tiling window manager then you may wish to set this to false.
-- src: https://wezfurlong.org/wezterm/config/lua/config/adjust_window_size_when_changing_font_size.html#adjust_window_size_when_changing_font_size-true
config.adjust_window_size_when_changing_font_size = false

-- Remove all key bindings except the ones I use.
config.disable_default_key_bindings = true
config.keys = {
  { key = "=", mods = "CTRL", action = wezterm.action.IncreaseFontSize },
  { key = "-", mods = "CTRL", action = wezterm.action.DecreaseFontSize },
  { key = "0", mods = "CTRL", action = wezterm.action.ResetFontSize },
  { key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") },
  { key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
}

-- Smoother terminal experience! Though, it's not ignored when in Wayland... So
-- useless for now.
--config.max_fps = 120

return config

