#
# Feature-rich interactive Jira command line.
# src: https://github.com/ankitpokhrel/jira-cli
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ jira-cli-go ];

  # Symlink ~/.config/zsh/*
  xdg.configFile."zsh/completions/_jira".source = ./.config/zsh/completions/_jira;
  xdg.configFile."zsh/plugins/jira" = {
    source = ./.config/zsh/plugins/jira;
    recursive = true;
  };
}
