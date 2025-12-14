#
# GitHub CLI tool.
# src: https://cli.github.com/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    gh
    # Github Cli extension to display a dashboard with pull requests and issues: https://github.com/dlvhdr/gh-dash.
    gh-dash
  ];

  # Symlink ~/.config/zsh/completions/_gh
  xdg.configFile."zsh/completions/_gh".source = ./.config/zsh/completions/_gh;
  #xdg.configFile."mise/conf.d/copilot-cli.toml".source = ./.config/mise/conf.d/copilot-cli.toml;
}
