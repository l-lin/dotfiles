#
# A secure and free password manager for all of your devices.
# src: https://bitwarden.com/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ bitwarden-cli ];
}
