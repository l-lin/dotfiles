#
# Terminal emulators.
#

{ userSettings, ... }: {
  imports = [
    (./. + "/${userSettings.term}")
  ];
}
