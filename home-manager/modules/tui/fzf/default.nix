#
# Command-line fuzzy finder.
# src: https://github.com/junegunn/fzf
#

{ pkgs, ... }: {

  home.packages = with pkgs; [ fzf ];
  home.file."bin/fzf.zsh" = {
    source = ./fzf.zsh;
    executable = true;
  };
}
