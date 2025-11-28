#
# Nord Theme - Polar Night, Snow Storm, Frost, Aurora
# src: https://www.nordtheme.com/ and https://github.com/gbprod/nord.nvim
#

{ config, pkgs, ... }:
let
  polarity = "light";
in {
  theme = {
    inherit polarity;
    nvimColorScheme = "nord";
    nvimColorSchemePluginLua = ''
{
  "l-lin/nord.nvim",
  opts = {
    styles = {
      keywords = { bold = true },
    },
  },
}
'';
  };

  stylix = {
    inherit polarity;
    image = "${config.home.homeDirectory}/Pictures/${polarity}.jpg";
    cursor = {
      name = "Bibata-Modern-Ice";
      size = 24;
      package = pkgs.bibata-cursors;
    };
  };
}
