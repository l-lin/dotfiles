#
# Terminal User Interfaces.
#

{ userSettings, ... }: {
  imports = [
    ./docker.nix
    ./greetd.nix
    (./. + "/shell/${userSettings.shell}.nix")
  ];
}
