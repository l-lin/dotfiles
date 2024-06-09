#
# Graphical User Interfaces.
#

{ pkgs, userSettings, ... }: {
  imports = [
    (./. + "/wm/${userSettings.wmType}")
    ./browser/firefox
    ./browser/w3m
    ./dunst
    ./hyprpicker.nix
    ./jetbrains
    ./ncmpcpp.nix
    ./satty.nix
    ./wall
  ];

  home.packages = with pkgs; [
    # A simple multi-page document viewer for the MATE desktop: https://mate-desktop.org/
    mate.atril
    # A powerful knowledge base that works on top of a local folder of plain text Markdown files: https://obsidian.md/
    obsidian
  ];
}
