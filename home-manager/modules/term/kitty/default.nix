#
# The fast, feature-rich, GPU based terminal emulator.
# src: https://sw.kovidgoyal.net/kitty/
#

{ config, pkgs, ... }:
let
  palette = config.colorScheme.palette;
in {
  programs.kitty = {
    enable = true;
    theme = "Kanagawa";
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 13;
    };
    # https://sw.kovidgoyal.net/kitty/conf/
    settings = {
      # Bell
      visual_bell_duration = 0;
      enable_audio_bell = "no";
      bell_on_tab = "yes";

      window_padding_width = 12;
    };
  };

  home.packages = with pkgs; [
    # Themes for Kitty terminal emulator: https://github.com/kovidgoyal/kitty-themes
    kitty-themes
  ];
}
