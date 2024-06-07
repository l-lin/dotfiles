#
# A cat(1) clone with wings.
# src: https://github.com/sharkdp/bat
#

{ pkgs, ... }: {
  programs.bat = {
    enable = true;
    config = {
      # Specify desired highlighting theme (e.g. "TwoDark"). Run `bat --list-themes`
      # for a list of all available themes
      theme = "Catppuccin-mocha";
      # Show line numbers, Git modifications and file header (but no grid)
      style = "numbers,changes,header";
    };
  };
}
