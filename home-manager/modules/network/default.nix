#
# Networking tools.
#

{ fileExplorer, pkgs, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # Command-line DNS client for humans: https://doggo.mrkaran.dev/docs/
    doggo
  ];
}
