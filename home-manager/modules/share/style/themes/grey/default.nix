#
# A light theme for NeoVim, with a light grey background 
# src: https://github.com/yorickpeterse/nvim-grey
#

{ config, pkgs, ... }:
let
  polarity = "light";
in {

  theme = {
    inherit polarity;
    nvimColorScheme = "grey";
    nvimColorSchemePluginLua = "{ 'l-lin/nvim-grey' }";
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
