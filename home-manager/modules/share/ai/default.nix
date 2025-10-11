#
# AI related stuff.
#

{
  imports = [
    ./backlog.md
    ./claude-code
    #./crush
    ./dust
    #./open-codex
    ./opencode
  ];

  # Symlink ~/.config/zsh/secrets/.secrets.ai.
  xdg.configFile."zsh/secrets/.secrets.ai".source = ./.config/zsh/secrets/.secrets.ai;
  xdg.configFile."ai" = {
    source = ./.config/ai;
    recursive = true;
  };
}
