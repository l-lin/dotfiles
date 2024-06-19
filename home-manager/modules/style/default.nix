#
# Theme related stuff, like icons, cursors, ... using stylix to manage them.
# src: https://github.com/danth/stylix
#
# Palette matching for kanagawa (colors differ depending on the theme):
#
# background = base00
# foreground = base05
#
# [colors.normal]
# black   =
# red     = base08
# green   = base0B
# yellow  = base0A
# blue    = base0D
# magenta = base0E
# cyan    = base0C
# white   = base06
#
# [colors.bright]
# black   = base04
# red     =
# green   =
# yellow  =
# blue    =
# magenta =
# cyan    =
# white   = base05
#
# [colors.selection]
# background =
# foreground = base06
#

{ inputs, pkgs, userSettings, ... }:
let
  # Iconic font aggregator, collection, & patcher. 3,600+ icons, 50+ patched fonts: https://nerdfonts.com/
  # Find your fonts at https://www.nerdfonts.com/font-downloads.
  nerdfonts = pkgs.nerdfonts.override {
    fonts = [
      "Ubuntu"
      "JetBrainsMono"
    ];
  };
in {
  imports = [
    inputs.stylix.homeManagerModules.stylix
    ./themes
  ];

  stylix = {
    enable = true;
    base16Scheme = (./. + "/themes/${userSettings.theme}/colorscheme.yaml");
    fonts = {
      monospace = {
        name = "JetBrainsMono Nerd Font";
        package = nerdfonts;
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        terminal = 13;
        applications = 12;
        popups = 12;
        desktop = 12;
      };
    };
    targets = {
      hyprland.enable = false;
      gtk.enable = false;
      swaylock.enable = false;
      tmux.enable = false;
      waybar.enable = false;
      wpaperd.enable = false;
    };
  };

  gtk.enable = true;
}
