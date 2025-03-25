#
# Powerful yet simple to use screenshot software.
# src: https://github.com/flameshot-org/flameshot
#

{ config, pkgs, ... }:
let
  palette = config.lib.stylix.colors.withHashtag;
in {
  home.packages = with pkgs; [ flameshot ];

  # Example: https://github.com/flameshot-org/flameshot/blob/master/flameshot.example.ini
  xdg.configFile."flameshot/flameshot.ini".text = with palette; ''
[General]
;; Main UI color
;; Color is any valid hex code or W3C color name
uiColor=${base0D-hex}

;; Last used color
;; Color is any valid hex code or W3C color name
drawColor=${base05-hex}

;; Image Save Path
savePath=${config.xdg.userDirs.pictures}/Screenshots

;; Show the help screen on startup (bool)
showHelp=false

;; Show desktop notifications (bool)
showDesktopNotification=false

;; Whether the tray icon is disabled (bool)
disabledTrayIcon=true

;; Automatically close daemon when it's not needed (not available on Windows)
autoCloseIdleDaemon=true
'';
}
