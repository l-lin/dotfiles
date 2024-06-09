#
# TUI file manager
#

{ userSettings, ... }: {
  imports = [
    (./. + "/${userSettings.tuiFileManager}")
  ];
}
