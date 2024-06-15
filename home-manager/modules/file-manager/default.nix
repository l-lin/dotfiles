#
# File manager.
#

{ userSettings, ... }: {
  imports = [
    (./. + "/${userSettings.fileManager}")
  ];
}
