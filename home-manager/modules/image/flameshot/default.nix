#
# Powerful yet simple to use screenshot software.
# src: https://github.com/flameshot-org/flameshot
#

{ config, pkgs, ... }:
let
  palette = config.lib.stylix.colors.withHashtag;
in {
  home.packages = with pkgs; [ flameshot ];

  xdg.configFile."flameshot/flameshot.ini".text = with palette; ''
[General]
uiColor=${base0D-hex}
drawColor=${base05-hex}
savePath=${config.xdg.userDirs.pictures}/Screenshots
'';
}
