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
    specs = {
      github_light_high_contrast = {
        bg0 = "#EFF1F5",
        bg1 = "#EFF1F5",
        canvas = {
          default = "#FFFFFF",
          inset = "#FFFFFF",
          overlay = "#FFFFFF",
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
