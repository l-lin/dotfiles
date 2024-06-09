#
# Terminal User Interfaces.
#

{ userSettings, ... }: {
  imports = [
    ./greetd.nix
    (./. + "/shell/${userSettings.shell}.nix")
  ];
}
