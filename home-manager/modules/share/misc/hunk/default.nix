#
# Review-first terminal diff viewer for agentic coders.
# src: https://github.com/modem-dev/hunk/
#

{ config, ... }:
let
  palette = config.lib.stylix.colors.withHashtag;
  baseTheme = if (config.theme.polarity == "dark") then "kanagawa" else "github-light-high-contrast";
in {
  xdg.configFile."mise/conf.d/hunk.toml".source = ./.config/mise/conf.d/hunk.toml;
  xdg.configFile."hunk/config.toml".text = with palette; ''
theme = "custom"
# auto, split, stack
mode = "auto"
vcs = "git"
watch = false
exclude_untracked = false
line_numbers = true
wrap_lines = true
agent_notes = true
transparent_background = false

[custom_theme]
base = "${baseTheme}"
appearance = "${config.theme.polarity}"
background = "${base00-hex}"
contextBg = "${base00-hex}"
lineNumberBg = "${base00-hex}"
panel = "${base00-hex}"
'';
}
