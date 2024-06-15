#
# Graphical User Interfaces.
#

{ pkgs, userSettings, ... }: {
  imports = [
    ./theme
    (./. + "/wm/${userSettings.wmType}")
  ];

  home.packages = with pkgs; [
    # Comprehensive, professional-quality productivity suite, a variant of openoffice.org: https://libreoffice.org/
    libreoffice
    # A simple multi-page document viewer for the MATE desktop: https://mate-desktop.org/
    mate.atril
    # A powerful knowledge base that works on top of a local folder of plain text Markdown files: https://obsidian.md/
    obsidian
    # Pulseaudio volume control: https://github.com/cdemoulins/pamixer
    pamixer
  ];
}
