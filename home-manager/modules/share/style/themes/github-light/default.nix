#
# GitHub's themes
# src: https://github.com/projekt0n/github-nvim-theme
#

{ config, pkgs, ... }:
let
  polarity = "light";
  palette = config.lib.stylix.colors.withHashtag;
in {

  theme = {
    inherit polarity;
    nvimColorScheme = "github_light_high_contrast";
    nvimColorSchemePluginLua = with palette; ''
{
  "projekt0n/github-nvim-theme",
  lazy = false,
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
        RenderMarkdownCodeInline = { link = TreesitterContext },
        SnacksIndent = { fg = "#E6E6E6" },
        LspReferenceRead = { link = "PmenuSel" },
        LspReferenceWrite = { link = "PmenuSel" },
        LspReferenceText = { link = "PmenuSel" },
        LspReferenceTarget = { link = "PmenuSel" },
      },
      github_light = {
        NonText = { fg = "palette.gray" },
        SnacksPickerMatch = { link = "Search" },
        TreesitterContext = { bg = "#E6E6E6" },
        RenderMarkdownCodeInline = { link = TreesitterContext },
        SnacksIndent = { fg = "#E6E6E6" },
        LspReferenceRead = { link = "PmenuSel" },
        LspReferenceWrite = { link = "PmenuSel" },
        LspReferenceTarget = { link = "PmenuSel" },
      },
    },
    specs = {
      github_light_high_contrast = {
        bg0 = "${base00-hex}",
        bg1 = "${base00-hex}",
        canvas = {
          default = "#FFFFFF",
          inset = "#FFFFFF",
          overlay = "#FFFFFF",
        },
        syntax = {
          keyword = "black",
        },
      },
      github_light = {
        bg0 = "${base00-hex}",
        bg1 = "${base00-hex}",
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
},
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
