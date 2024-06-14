#
# Theme related stuff, like icons, cursors, ...
#

{ pkgs, ... }:
let
  # Iconic font aggregator, collection, & patcher. 3,600+ icons, 50+ patched fonts: https://nerdfonts.com/
  nerdfonts = pkgs.nerdfonts.override {
    fonts = [
      "JetBrainsMono"
    ];
  };

  # Soothing pastel theme for GTK: https://github.com/catppuccin/gtk
  theme = {
    name = "catppuccin-gtk";
    package = pkgs.catppuccin-gtk;
  };
  font = {
    name = "JetBrainsMono Nerd Font";
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
    name = "MoreWaita";
    package = pkgs.morewaita-icon-theme;
  };
in {
  home.packages = with pkgs; [
      font.package
      cursorTheme.package
      iconTheme.package
      gnome.adwaita-icon-theme
      papirus-icon-theme
  ];

  home = {
    sessionVariables = {
      GTK_THEME = theme.name;
      XCURSOR_THEME = cursorTheme.name;
      XCURSOR_SIZE = "${toString cursorTheme.size}";
    };
    pointerCursor =
      cursorTheme
      // {
        gtk.enable = true;
      };

    file = {
      ".config/gtk-4.0/gtk.css".text = ''
        window.messagedialog .response-area > button,
        window.dialog.message .dialog-action-area > button,
        .background.csd{
          border-radius: 8px;
        }
      '';
    };
  };

  fonts.fontconfig.enable = true;

  gtk = {
    inherit font cursorTheme iconTheme;
    theme.name = theme.name;
    enable = true;
    gtk3.extraCss = ''
      headerbar, .titlebar,
      .csd:not(.popup):not(tooltip):not(messagedialog) decoration{
        border-radius: 8px;
      }
    '';
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
