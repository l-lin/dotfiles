#
# ⚡️Blazing fast terminal file manager written in Rust, based on async I/O.
# src: https://yazi-rs.github.io/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ yazi ];
}
