#
# AI related stuff.
#

{
  imports = [
    ./claude-code
    ./dust
    ./opencode
    ./pi
    ./tuicr
  ];

  xdg.configFile = {
    "zsh/secrets/.secrets.ai".source = ./.config/zsh/secrets/.secrets.ai;
    "ai" = {
      source = ./.config/ai;
      recursive = true;
    };
  };
}
