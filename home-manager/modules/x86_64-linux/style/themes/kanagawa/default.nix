#
# Dark colorscheme inspired by the colors of the famous painting by Katsushika Hokusai.
# src: https://github.com/rebelot/kanagawa.nvim
#

{ pkgs, ... }: {
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
