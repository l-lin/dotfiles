#
# 🪨 A collection of contrast-based Vim/Neovim colorschemes.
# src: https://github.com/zenbones-theme/zenbones.nvim
#

{ config, pkgs, ... }:
let
  polarity = "light";
in {

  theme = {
    inherit polarity;
    nvimColorScheme = "zenwritten";
    nvimColorSchemePluginLua = ''
{
  "zenbones-theme/zenbones.nvim",
  dependencies = "rktjmp/lush.nvim",
}
    '';
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
