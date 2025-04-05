#
# Rust programming language.
# src: https://nixos.wiki/wiki/Rust
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    cargo
    rustc
  ];
}
