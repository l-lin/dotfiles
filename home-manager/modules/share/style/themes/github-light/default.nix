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
    nvimColorSchemePluginLua = ''
{
  "projekt0n/github-nvim-theme",
  opts = {
    options = {
      styles = {
        keywords = "bold",
      },
    },
    groups = {
      github_light_high_contrast = {
        NonText = { fg = "palette.gray" },
        SnacksPickerMatch = { link = "Search" },
        TreesitterContext = { bg = "#E6E6E6" },
        RenderMarkdownCodeInline = { bg = "#E6E6E6" },
      },
    },
    specs = {
      github_light_high_contrast = {
        bg0 = "#EFF1F5",
        bg1 = "#EFF1F5",
        canvas = {
          default = "#FFFFFF",
          inset = "#FFFFFF",
          overlay = "#FFFFFF",
        },
        syntax = {
          keyword = "black",
        },
      },
    },
  },
  config = function(_, opts)
    require("github-theme").setup(opts)
  end,
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
