#
# Graphical User Interfaces.
#

{ pkgs, userSettings, ... }: {
  imports = [
    ./audio
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
    # Comprehensive, professional-quality productivity suite, a variant of openoffice.org: https://libreoffice.org/
    libreoffice
    # A simple multi-page document viewer for the MATE desktop: https://mate-desktop.org/
    mate.atril
    # A powerful knowledge base that works on top of a local folder of plain text Markdown files: https://obsidian.md/
    obsidian
  ];
}
