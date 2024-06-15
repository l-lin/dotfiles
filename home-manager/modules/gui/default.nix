#
# Graphical User Interfaces.
#

{ pkgs, userSettings, ... }: {
  imports = [
    ./image
    ./satty
    ./theme
    ./wall
    (./. + "/wm/${userSettings.wmType}")
  ];

  home.packages = with pkgs; [
    # Comprehensive, professional-quality productivity suite, a variant of openoffice.org: https://libreoffice.org/
    libreoffice
    # The GNU Image Manipulation Program: https://www.gimp.org/
    gimp
    # A wlroots-compatible Wayland color picker that does not suck.
    #
    # /!\ Need to set the cursor theme for hyprpicker to work.
    # See https://github.com/hyprwm/hyprpicker/issues/51.
    # Cursor set in `theme/default.nix`.
    #
    # src: https://github.com/hyprwm/hyprpicker
    hyprpicker
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
