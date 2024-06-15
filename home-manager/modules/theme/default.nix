#
# Theme related stuff, like icons, cursors, ...
#

{ pkgs, ... }:
let
  # Iconic font aggregator, collection, & patcher. 3,600+ icons, 50+ patched fonts: https://nerdfonts.com/
  # Find your fonts at https://www.nerdfonts.com/font-downloads.
  nerdfonts = pkgs.nerdfonts.override {
    fonts = [
      "Ubuntu"
      "JetBrainsMono"
    ];
  };

  # Soothing pastel theme for GTK: https://github.com/catppuccin/gtk
  theme = {
    name = "Catppuccin-Mocha-Compact-Blue-Dark";
    # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/pkgs/data/themes/catppuccin-gtk/default.nix
    package = pkgs.catppuccin-gtk.override {
      size = "compact";
      variant = "mocha";
    };
  };
  font = {
    name = "Ubuntu Nerd Font";
    package = nerdfonts;
    size = 12;
  };
  # Flat colorful design icon theme: https://github.com/vinceliuice/Qogir-icon-theme
  cursorTheme = {
    name = "Qogir";
    size = 24;
    package = pkgs.qogir-icon-theme;
  };
  # An Adwaita style extra icons theme for Gnome Shell: https://github.com/somepaulo/MoreWaita
  iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.papirus-icon-theme;
  };
in {
  imports = [
    ./colorscheme
  ];

  home = {
    sessionVariables = {
      XCURSOR_THEME = cursorTheme.name;
      XCURSOR_SIZE = "${toString cursorTheme.size}";
    };
    pointerCursor = {
      gtk.enable = true;
      name = cursorTheme.name;
      size = cursorTheme.size;
      package = cursorTheme.package;
    };
  };

  fonts.fontconfig.enable = true;

  gtk = {
    inherit font cursorTheme iconTheme theme;
    enable = true;
  };

  # Enable toggle dark/light mode
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };
}
