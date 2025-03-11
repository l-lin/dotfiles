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
    nvimColorScheme = "kanagawa";
    nvimColorSchemePluginLua = ''
{
  "rebelot/kanagawa.nvim",
  opts = {
    keywordStyle = { bold = true, italic = false },
    overrides = function(colors)
      local theme = colors.theme
      return {
        SnacksPickerMatch = { link = "Search" }
      }
    end
  }
}
    '';
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

  gtk = {
    iconTheme = {
      # An icon theme for the Kanagawa colour palette: https://github.com/Fausto-Korpsvart/Kanagawa-GKT-Theme
      name = "Kanagawa";
      package = pkgs.kanagawa-icon-theme;
    };
    theme = {
      # Soothing pastel theme for GTK: https://github.com/catppuccin/gtk
      name = "catppuccin-mocha-blue-compact";
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/pkgs/data/themes/catppuccin-gtk/default.nix
      package = pkgs.catppuccin-gtk.override {
        size = "compact";
        variant = "mocha";
      };
    };
  };
}
