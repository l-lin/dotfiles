#
# Presenterm lets you create presentations in markdown format and run them
# from your terminal, with support for image and animated gif support,
# highly customizable themes, code highlighting, exporting presentations
# into PDF format, and plenty of other features.
# src: https://mfontanini.github.io/presenterm/introduction.html
#

{ config, pkgs, ... }:
let
  theme = if (config.theme.polarity == "dark") then "catppuccin-mocha" else "catppuccin-latte";
in {
  home.packages = with pkgs; [ presenterm ];

  xdg.configFile."presenterm/config.yaml".text = ''
# yaml-language-server: $schema=https://raw.githubusercontent.com/mfontanini/presenterm/master/config-file-schema.json
defaults:
  # The theme to use by default in every presentation unless overridden: https://mfontanini.github.io/presenterm/guides/themes.html.
  # You can check all available themes by executing `presenterm --list-themes`.
  theme: ${theme}

  # I'm using tmux, so it's not rendering well with the default option, so I need to set it to kitty-local so the image is rendered correctly.
  image_protocol: kitty-local

options:
  # Whether to treat a thematic break as a slide end.
  end_slide_shorthand: true
  '';
}
