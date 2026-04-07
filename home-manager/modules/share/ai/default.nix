#
# AI related stuff.
#

{
  imports = [
    ./claude-code
    ./dust
    ./ollama
    #./opencode
    ./pi
  ];

  xdg.configFile = {
    "zsh/secrets/.secrets.ai".source = ./.config/zsh/secrets/.secrets.ai;
    "ai" = {
      source = ./.config/ai;
      recursive = true;
    };
  };

  home.sessionVariables = {
    # Force agent mode for pup (Datadog CLI): https://github.com/datadog-labs/pup#agent-mode
    FORCE_AGENT_MODE = "true";
  };
}
