#
# AI pair programming in your terminal.
# src: https://github.com/paul-gauthier/aider
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ aider-chat ];

  # Symlink ~/.config/zsh/functions/aider-convention-scraper.
  xdg.configFile."zsh/functions/aider-convention-scraper".source = ./.config/zsh/functions/aider-convention-scraper;
}
