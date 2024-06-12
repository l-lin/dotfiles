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
    ./hyprpicker
    ./gtk
    ./image
    ./jetbrains
    ./messaging
    ./satty
    ./video
    ./wall
  ];

  home.packages = with pkgs; [
    # Comprehensive, professional-quality productivity suite, a variant of openoffice.org: https://libreoffice.org/
    libreoffice
    # The GNU Image Manipulation Program: https://www.gimp.org/
    gimp
    # A simple multi-page document viewer for the MATE desktop: https://mate-desktop.org/
    mate.atril
    # A powerful knowledge base that works on top of a local folder of plain text Markdown files: https://obsidian.md/
    obsidian
    # Pulseaudio volume control: https://github.com/cdemoulins/pamixer
    pamixer
    # Simple animated GIF screen recorder with an easy to use interface: https://github.com/phw/peek
    peek
  ];
}
