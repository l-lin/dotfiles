#
# Networking config always goes in your system configuration.
# Use `nmtui` command to configure your network connection.
# src: https://nixos.wiki/wiki/Networking
#

{ systemSettings, ... }: {
  networking = {
    hostName = systemSettings.hostname;
    networkmanager.enable = true;
  };
}
