#
# Dark colorscheme inspired by the colors of the famous painting by Katsushika Hokusai.
# src: https://github.com/rebelot/kanagawa.nvim
#

{ config, pkgs, ... }:
let
  polarity = "dark";
in {
  theme = {
    inherit polarity;
    nvimColorScheme = "kanagawa-wave";
    nvimColorSchemePluginLua = "{ 'rebelot/kanagawa.nvim' }";
  };

  stylix = {
    inherit polarity;
    # stylix needs a background image when gnome is enable.
    image = "${config.home.homeDirectory}/Pictures/${polarity}.jpg";
    cursor = {
      # Material Based Cursor Theme: https://github.com/ful1e5/Bibata_Cursor
      name = "Bibata-Modern-Ice";
      size = 24;
      package = pkgs.bibata-cursors;
    };
  };
}
