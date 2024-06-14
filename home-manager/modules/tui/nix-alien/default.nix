#
# Run unpatched binaries on Nix/NixOS.
# Useful if you want to execute some binaries on NixOS.
#
# src:
# - https://github.com/thiagokokada/nix-alien
# - https://nixos.wiki/wiki/Packaging/Binaries
#

{ inputs, systemSettings, ... }: {
  home.packages = with inputs.nix-alien.packages.${systemSettings.system}; [ nix-alien ];
}
