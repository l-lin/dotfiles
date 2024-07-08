#
# A handy way to save and run project-specific commands.
# src: https://github.com/casey/just
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ just ];
 
  # Symlink ~/.config/zsh/completions/
  xdg.configFile."zsh/completions/_just".source = ./.config/zsh/completions/_just;
}
