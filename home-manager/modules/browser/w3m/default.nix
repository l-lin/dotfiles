#
# Text mode web browser.
# src: https://w3m.sourceforge.net/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ w3m ];

  # Symlink to ~/.w3m/keymap
  home.file.".w3m/keymap".source = ./config/keymap;
}
