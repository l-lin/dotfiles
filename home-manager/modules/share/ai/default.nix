#
# AI related stuff.
#

{
  imports = [
    ./claude-code
    #./crush
    ./dust
    #./open-codex
    ./opencode
  ];

  xdg.configFile = {
    "zsh/secrets/.secrets.ai".source = ./.config/zsh/secrets/.secrets.ai;
    "ai" = {
      source = ./.config/ai;
      recursive = true;
    };
  };
}
