#
# A launcher/menu program.
# src: https://github.com/lbonn/rofi
#

{ pkgs, ... }: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    font = "JetBrainsMono Nerd font 14";
    extraConfig = {
      modi = "drun";
      display-drun = "";
      show-icons = true;
      drun-display-format = "{name}";
      sidebar-mode = false;
    };
  };
}
