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
      theme = "catppuccin-mocha";
      # Show line numbers, Git modifications and file header (but no grid)
      style = "numbers,changes,header";
    };
    themes = {
      catppuccin-mocha = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "d714cc1d358ea51bfc02550dabab693f70cccea0";
          sha256 = "Q5B4NDrfCIK3UAMs94vdXnR42k4AXCqZz6sRn8bzmf4=";
        };
        file = "themes/Catppuccin Mocha.tmTheme";
      };
    };
  };
}
