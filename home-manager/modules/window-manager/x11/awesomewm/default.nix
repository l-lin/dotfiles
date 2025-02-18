#
# Highly configurable X window manager.
# src: https://awesomewm.org/apidoc/index.html
#

{ userSettings, ... }: {
  # HACK: Using native installation.

  xdg.configFile."awesome/config.lua".text = ''
local M = {}
M.modkey = "Mod4"
M.terminal = "${userSettings.term}"
M.tags = { "1", "2", "3", "4", "5" }
return M
  '';
}
