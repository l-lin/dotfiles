#
# Wallpaper.
#

{ config, ... }: {
  # Modern wallpaper daemon for Wayland.
  # src: https://github.com/danyspin97/wpaperd
  programs.wpaperd = {
    enable = true;
    settings = {
      any = {
        duration = "1h";
        mode = "center";
        path = ./. + "/${config.theme.polarity}/";
      };
    };
  };
}
