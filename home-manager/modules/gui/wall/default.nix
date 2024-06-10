#
# Wallpapers.
#

{ pkgs, ... }: {
  home.file."Pictures/cat.jpg".source = ./cat.jpg;
  home.file."Pictures/hi.png".source = ./hi.png;
  home.file."Pictures/zelda_wind_walker.png".source = ./zelda_wind_walker.png;
  home.file."Pictures/nix.png".source = ./nix.png;

  home.packages = with pkgs; [
    # Wallpaper tool for Wayland conpositors: https://github.com/swaywm/swaybg
    swaybg
  ];
}
