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
    ./satty.nix
    ./wall
  ];

  home.packages = with pkgs; [
    # A powerful knowledge base that works on top of a local folder of plain text Markdown files: https://obsidian.md/
    obsidian
  ];
}
