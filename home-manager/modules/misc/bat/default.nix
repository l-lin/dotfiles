#
# A cat(1) clone with wings.
# src: https://github.com/sharkdp/bat
#

{ pkgs, ... }: {
  programs.bat = {
    enable = true;
    config = {
      # Show line numbers, Git modifications and file header (but no grid)
      style = "numbers,changes,header";
    };
  };
}
