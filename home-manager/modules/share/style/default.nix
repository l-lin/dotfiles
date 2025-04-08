#
# Theme related stuff, like icons, cursors, ... using stylix to manage them.
# src: https://github.com/danth/stylix
#
# Palette matching for kanagawa (colors differ depending on the theme):
#
# background = base00
# foreground = base05
#
# [colors.normal]
# black   =
# red     = base08
# green   = base0B
# yellow  = base0A
# blue    = base0D
# magenta = base0E
# cyan    = base0C
# white   = base06
#
# [colors.bright]
# black   = base04
# red     =
# green   =
# yellow  =
# blue    =
# magenta =
# cyan    =
# white   = base05
#
# [colors.selection]
# background =
# foreground = base06
#

{ inputs, pkgs, userSettings, ... }: {
  imports = [
    inputs.stylix.homeManagerModules.stylix
    ./themes
  ];

  stylix = {
    enable = true;
    autoEnable = false;
    base16Scheme = (./. + "/themes/${userSettings.theme}/colorscheme.yaml");
    fonts = {
      monospace = {
        # kitty use fontconfig, which keeps track of all the fonts and their
        # paths on the system. The new namespace moves around some fonts, and it
        # seems the fontconfig cache has not been updated.
        # To manually reload the fontconfig cache, execute: `fc-cache -r`.
        # src: https://github.com/danth/stylix/issues/650#issuecomment-2509746627
        #
        # List of Nerd Fonts can be found here:
        # https://github.com/NixOS/nixpkgs/blob/c55d81a2ef622a0838d2c398ae6f8523862227af/pkgs/data/fonts/nerd-fonts/manifests/fonts.json#L315
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        terminal = 13;
        applications = 12;
        popups = 12;
        desktop = 12;
      };
    };
    targets = {
      # WARN: Do not enable gtk! Otherwise, you might no longer login in your Ubuntu GUI...
      bat.enable = true;
      btop.enable = true;
      # Define my own color to set in another env variable, or file?
      fzf.enable = false;
      gnome.enable = true;
      lazygit.enable = true;
      kitty.enable = true;
      kitty.variant256Colors = true;
      rofi.enable = true;
      wezterm.enable = true;
    };
  };

  gtk.enable = true;
}
