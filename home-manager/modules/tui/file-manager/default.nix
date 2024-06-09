#
# TUI file manager
#

{ userSettings, ... }: {
  imports = [
    (./. + "/${userSettings.fileManager}")
  ];
}
