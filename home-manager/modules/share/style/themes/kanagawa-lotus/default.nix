#
# Dark colorscheme inspired by the colors of the famous painting by Katsushika Hokusai.
# src: https://github.com/rebelot/kanagawa.nvim
#

{ config, pkgs, ... }:
let
  polarity = "light";
in {
  theme = {
    inherit polarity;
    nvimColorScheme = "kanagawa-lotus";
    nvimColorSchemePluginLua = "{ 'rebelot/kanagawa.nvim' }";
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
