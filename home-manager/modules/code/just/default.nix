#
# A handy way to save and run project-specific commands.
# src: https://github.com/casey/just
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ just ];
 
  # Symlink ~/.config/nvim/snippets/just.snippets
  xdg.configFile."nvim/snippets/just.snippets".source = ./.config/nvim/snippets/just.snippets;
  # Symlink ~/.config/zsh/completions/_just
  xdg.configFile."zsh/completions/_just".source = ./.config/zsh/completions/_just;
}
