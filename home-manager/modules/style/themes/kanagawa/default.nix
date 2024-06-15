#
# Dark colorscheme inspired by the colors of the famous painting by Katsushika Hokusai.
# src: https://github.com/rebelot/kanagawa.nvim
#

{ pkgs, ... }:
let
  backgroundImage = ../../../image/config/summer-dark.png;
  polarity = "dark";
in {

  theme = {
    inherit backgroundImage polarity;
    nvimColorScheme = "kanagawa";
    nvimColorSchemePluginLua = "{ 'rebelot/kanagawa.nvim' }";
  };

  stylix = {
    inherit polarity;
    image = backgroundImage;
    cursor = {
      # Material Based Cursor Theme: https://github.com/ful1e5/Bibata_Cursor
      name = "Bibata-Modern-Ice";
      size = 24;
      package = pkgs.bibata-cursors;
    };
  };

  gtk = {
    iconTheme = {
      # A GTK theme with the Kanagawa colour palette: https://github.com/Fausto-Korpsvart/Kanagawa-GKT-Theme
      name = "Kanagawa";
      package = pkgs.kanagawa-icon-theme;

      # Pixel perfect icon theme for Linux: https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
      #name = "Papirus-Dark";
      #package = pkgs.papirus-icon-theme;
    };
    theme = {
      # An icon theme for the Kanagawa colour palette: https://github.com/Fausto-Korpsvart/Kanagawa-GKT-Theme
      name = "Kanagawa-BL";
      package = pkgs.kanagawa-gtk-theme;

      # Soothing pastel theme for GTK: https://github.com/catppuccin/gtk
      #name = "Catppuccin-Mocha-Compact-Blue-Dark";
      ## https://github.com/NixOS/nixpkgs/blob/nixos-24.05/pkgs/data/themes/catppuccin-gtk/default.nix
      #package = pkgs.catppuccin-gtk.override {
      #  size = "compact";
      #  variant = "mocha";
      #};
    };
  };
}
