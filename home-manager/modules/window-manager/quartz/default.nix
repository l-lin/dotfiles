#
# Display server for MacOS.
# src: https://developer.apple.com/documentation/quartz/quartz-composer
#

{ userSettings, ... }: {
  imports = [
    (./. + "/${userSettings.wm}")
  ];
}
