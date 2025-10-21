#
# src: https://nixos.org/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Lints and suggestions for the nix programming language: https://github.com/oppiliappan/statix
    statix
  ];
}
