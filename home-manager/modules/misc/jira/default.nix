#
# Feature-rich interactive Jira command line.
# src: https://github.com/ankitpokhrel/jira-cli
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ jira-cli-go ];

  # Symlink ~/.config/zsh/*
  xdg.configFile."zsh/completions/_jira".source = ./.config/zsh/completions/_jira;
  xdg.configFile."zsh/plugins/jira/jira.plugin.zsh".source = ./.config/zsh/plugins/jira/jira.plugin.zsh;
}
