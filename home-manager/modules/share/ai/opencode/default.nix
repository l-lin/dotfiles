#
# The AI coding agent built for the terminal.
# src: https://opencode.ai/
#

{
  xdg.configFile."mise/conf.d/opencode.toml".source = ./.config/mise/conf.d/opencode.toml;
  xdg.configFile."opencode/config.json".source = ./.config/opencode/config.json;
  xdg.configFile."opencode/command" = {
    source = ../.config/ai/prompts;
    recursive = true;
  };
  # xdg.configFile."opencode/agent" = {
  #   source = ../.config/ai/agents;
  #   recursive = true;
  # };
}
