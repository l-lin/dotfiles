#
# Nord Theme - Polar Night, Snow Storm, Frost, Aurora
# src: https://www.nordtheme.com/ and https://github.com/gbprod/nord.nvim
#

{ config, pkgs, ... }:
let
  polarity = "dark";
in {
  theme = {
    inherit polarity;
    nvimColorScheme = "nord";
    nvimColorSchemePluginLua = ''
{
  "gbprod/nord.nvim",
  opts = {
    errors = "fg",
    styles = {
      keywords = { bold = true },
    },
    on_highlights = function(highlights, colors)
      highlights.SnacksPickerMatch = { link = "SpecialComment" }
    end,
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
