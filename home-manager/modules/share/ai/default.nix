#
# AI related stuff.
#

{
  imports = [
    ./claude-code
    ./dust
    ./opencode
    ./pi
  ];

  xdg.configFile = {
    "zsh/secrets/.secrets.ai".source = ./.config/zsh/secrets/.secrets.ai;
    "ai" = {
      source = ./.config/ai;
      recursive = true;
    };
  };
}
