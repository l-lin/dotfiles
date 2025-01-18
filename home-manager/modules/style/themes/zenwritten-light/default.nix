#
# 🪨 A collection of contrast-based Vim/Neovim colorschemes.
# src: https://github.com/zenbones-theme/zenbones.nvim
#

{ pkgs, ... }:
let
  polarity = "light";
in {

  theme = {
    inherit polarity;
    ghosttyColorScheme = "AtomOneLight";
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
    image = ../../../image/wallpaper/pictures/sky.png;
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
