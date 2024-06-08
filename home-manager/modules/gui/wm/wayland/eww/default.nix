#
# Standalone widget system in any window manager.
# src: https://github.com/elkowar/eww
#

{ colorscheme, pkgs, ... }: {
  home.packages = with pkgs; [ eww ];

  # Symlink to ~/.config/eww
  xdg.configFile.eww = {
    source = ./config;
    recursive = true;
  };

  # Symlink to ~/.config/eww/style/_colors.scss
  xdg.configFile."eww/style/_colors.scss".text = ''
    $background : #${colorscheme.background};
    $foreground : #${colorscheme.foreground};
    $background-alt : #${colorscheme.mbg};
    $background-light : #${colorscheme.color0};
    $foreground-alt : #${colorscheme.color7};
    $red : #${colorscheme.color1};
    $red-light : #${colorscheme.color9};
    $green : #${colorscheme.color2};
    $green-light : #${colorscheme.color10};
    $yellow : #${colorscheme.color3};
    $yellow-light : #${colorscheme.color11};
    $blue : #${colorscheme.color4};
    $blue-light : #${colorscheme.color12};
    $cyan : #${colorscheme.color6};
    $cyan-light : #${colorscheme.color14};
    $magenta : #${colorscheme.color5};
    $magenta-light : #${colorscheme.color13};
    $comment : #${colorscheme.comment};
    $accent : #${colorscheme.accent};
  '';
}
