#
# Highly configurable X window manager.
# src: https://awesomewm.org/apidoc/index.html
#

{ config, userSettings, ... }:
let
  palette = config.lib.stylix.colors.withHashtag;
in {
  # HACK: Using native installation installed with `sudo apt install awesome`.

  # On awesomewm, it's using the gpg-agent instead of ssh-agent, and it's quite
  # slow when signing git commits... So forcing using ssh-agent by setting
  # SSH_AUTH_LOCK.
  home.sessionVariables = {
    XDG_RUNTIME_DIR = "/run/user/$UID";
    SSH_AUTH_SOCK = "${config.home.sessionVariables.XDG_RUNTIME_DIR}/ssh-agent.socket";
  };

  xdg.configFile."awesome/config.lua".text = ''
local M = {}
M.modkey = "Mod4"
M.terminal = "${userSettings.term}"
M.polarity = "${config.theme.polarity}"
return M
  '';
  xdg.configFile."awesome" = {
    source = ./.config/awesome;
    recursive = true;
  };

  xdg.configFile."awesome/theme/colors.lua".text = with palette; ''
local M = {}
M.bg_normal        = "${base00-hex}"
M.bg_focus         = "${base0D-hex}"
M.bg_urgent        = M.bg_normal
M.bg_warning       = M.bg_normal
M.bg_minimize      = "${base07-hex}"
M.bg_systray       = M.bg_normal

M.fg_normal        = "${base05-hex}"
M.fg_focus         = M.bg_normal
M.fg_urgent        = "${base08-hex}"
M.fg_warning       = "${base09-hex}"
M.fg_minimize      = M.bg_minimize

M.taglist_fg_empty = M.bg_minimize

M.border_focus     = M.bg_focus

return M
  '';
}
