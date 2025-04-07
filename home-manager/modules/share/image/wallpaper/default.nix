#
# Wallpaper.
#

{ config, ... }: {
  home.file."Pictures" = {
    source = ./Pictures;
    recursive = true;
  };
  home.file."Pictures/wallpaper.jpg".source = ./Pictures/${config.theme.polarity}.jpg;
}
