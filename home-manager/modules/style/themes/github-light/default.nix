#
# 
# src: https://github.com/rebelot/kanagawa.nvim
#

{ pkgs, ... }:
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
    specs = {
      github_light_high_contrast = {
        bg0 = "#f2eede",
        bg1 = "#f2eede",
        canvas = {
          default = "#ffffff",
          inset = "#ffffff",
          overlay = "#ffffff",
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
    # For some reason, stylix needs a background image...
    image = ../../../image/wallpaper/light/scarlet-tree.png;
    cursor = {
      # Material Based Cursor Theme: https://github.com/ful1e5/Bibata_Cursor
      name = "Bibata-Modern-Classic";
      size = 24;
      package = pkgs.bibata-cursors;

      # Flat colorful design icon theme: https://github.com/vinceliuice/Qogir-icon-theme
      #name = "Qogir";
      #size = 24;
      #package = pkgs.qogir-icon-theme;
    };
  };

  gtk = {
    iconTheme = {
      # Pixel perfect icon theme for Linux: https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
      name = "Papirus-Light";
      package = pkgs.papirus-icon-theme;
    };
    theme = {
      # Soothing pastel theme for GTK: https://github.com/catppuccin/gtk
      name = "Catppuccin-Latte-Compact-Blue-Light";
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/pkgs/data/themes/catppuccin-gtk/default.nix
      package = pkgs.catppuccin-gtk.override {
        size = "compact";
        variant = "latte";
      };
    };
  };
}
