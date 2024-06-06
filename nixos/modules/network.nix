#
# Networking config always goes in your system configuration.
#
# src: https://nixos.wiki/wiki/Networking
#

{ systemSettings, ... }: {
  networking = {
    hostName = systemSettings.hostname;
    networkmanager.enable = true;
  };
}
