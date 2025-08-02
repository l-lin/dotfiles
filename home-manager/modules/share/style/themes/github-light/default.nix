#
# GitHub's themes
# src: https://github.com/projekt0n/github-nvim-theme
#

{ config, pkgs, ... }:
let
  polarity = "light";
in {

  theme = {
    inherit polarity;
    nvimColorScheme = "github_light_high_contrast";
  };

  stylix = {
    inherit polarity;
    # stylix needs a background image when gnome is enable.
    image = "${config.home.homeDirectory}/Pictures/${polarity}.jpg";
    cursor = {
      # Material Based Cursor Theme: https://github.com/ful1e5/Bibata_Cursor
      name = "Bibata-Modern-Classic";
      size = 24;
      package = pkgs.bibata-cursors;
    };
  };
}
