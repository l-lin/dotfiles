#
# 🪨 A collection of contrast-based Vim/Neovim colorschemes.
# src: https://github.com/zenbones-theme/zenbones.nvim
#

{ pkgs, ... }: {
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
