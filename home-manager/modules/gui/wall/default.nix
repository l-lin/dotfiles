#
# Wallpapers.
#

{ pkgs, ... }: {

  home.file.".face".source = ./config/hi.png;
  home.file."Pictures/cat.jpg".source = ./config/cat.jpg;
  home.file."Pictures/hi.png".source = ./config/hi.png;
  home.file."Pictures/summer-dark.png".source = ./config/summer-dark.png;
  home.file."Pictures/summer-light.png".source = ./config/summer-light.png;

  home.packages = with pkgs; [
    # Wallpaper tool for Wayland conpositors: https://github.com/swaywm/swaybg
    swaybg
  ];
}
