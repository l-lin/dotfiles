#
# A secure and free password manager for all of your devices.
# src: https://bitwarden.com/
#

{ pkgs-bitwarden-cli, ... }: {
  home.packages = with pkgs-bitwarden-cli; [ bitwarden-cli ];
}
