#
# Highly configurable X window manager.
# src: https://awesomewm.org/apidoc/index.html
#

{ config, userSettings, ... }: {
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
M.tags = { "1", "2", "3", "4", "5" }
return M
  '';
}
