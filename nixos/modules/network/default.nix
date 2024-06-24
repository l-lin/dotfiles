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

    # Block hosts from several well-curated sources: https://github.com/StevenBlack/hosts
    stevenblack = {
      enable = true;
      block = [ "fakenews" "gambling" ];
    };
  };
}
