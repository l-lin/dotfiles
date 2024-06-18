#
# Networking config always goes in your system configuration.
# Use `nmtui` command to configure your network connection.
# src: https://nixos.wiki/wiki/Networking
#

{ fileExplorer, systemSettings, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  networking = {
    hostName = systemSettings.hostname;
    networkmanager.enable = true;
  };
}
