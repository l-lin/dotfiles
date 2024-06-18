#
# Terminal User Interfaces.
#

{ userSettings, ... }: {
  imports = [
    (./. + "/${userSettings.shell}")
  ];
}
