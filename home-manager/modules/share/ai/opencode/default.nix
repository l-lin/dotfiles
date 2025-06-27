#
# The AI coding agent built for the terminal.
# src: https://opencode.ai/
# WARNING: Not the same as github.com/opencode-ai/opencode! They share the same
# binary name though... So use one or the other, not both at the same time!
#

{
  xdg.configFile."mise/conf.d/opencode.toml".source = ./.config/mise/conf.d/opencode.toml;
  xdg.configFile."opencode/config.json".source = ./.config/opencode/config.json;
}
