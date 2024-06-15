#
# Dark colorscheme inspired by the colors of the famous painting by Katsushika Hokusai.
# src: https://github.com/rebelot/kanagawa.nvim
#

{ pkgs, ... }:
let
  backgroundImage = ../../../image/config/summer-dark.png;
in {
  stylix = {
    image = backgroundImage;
    polarity = "dark";
    cursor = {
      # Flat colorful design icon theme: https://github.com/vinceliuice/Qogir-icon-theme
      name = "Qogir";
      size = 24;
      package = pkgs.qogir-icon-theme;
    };
  };

  gtk = {
    iconTheme = {
      # Pixel perfect icon theme for Linux: https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    theme = {
      # Soothing pastel theme for GTK: https://github.com/catppuccin/gtk
      name = "Catppuccin-Mocha-Compact-Blue-Dark";
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/pkgs/data/themes/catppuccin-gtk/default.nix
      package = pkgs.catppuccin-gtk.override {
        size = "compact";
        variant = "mocha";
      };
    };
  };

  # Set background image at ~/.local/share/theme/background-image, will be used by Window compositor like Hyprland.
  xdg.dataFile."theme/background-image".source = backgroundImage;
}
