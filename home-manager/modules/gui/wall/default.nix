#
# Wallpapers.
#

{ pkgs, ... }: {

  home.file.".face".source = ./hi.png;
  home.file."Pictures/cat.jpg".source = ./cat.jpg;
  home.file."Pictures/hi.png".source = ./hi.png;
  home.file."Pictures/summer-dark.png".source = ./summer-dark.png;
  home.file."Pictures/summer-light.png".source = ./summer-light.png;

  home.packages = with pkgs; [
    # Wallpaper tool for Wayland conpositors: https://github.com/swaywm/swaybg
    swaybg
  ];
}
