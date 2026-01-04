#
# A handy way to save and run project-specific commands.
# src: https://github.com/casey/just
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ just ];
  xdg.configFile."zsh/completions/_just".source = ./.config/zsh/completions/_just;
}
