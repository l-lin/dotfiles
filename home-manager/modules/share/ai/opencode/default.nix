#
# The AI coding agent built for the terminal.
# src: https://opencode.ai/
#

{
  xdg.configFile."mise/conf.d/opencode.toml".source = ./.config/mise/conf.d/opencode.toml;
  xdg.configFile."opencode/config.json".source = ./.config/opencode/config.json;
  xdg.configFile."opencode/AGENTS.md".source = ../.config/ai/conventions/code.md;
}
