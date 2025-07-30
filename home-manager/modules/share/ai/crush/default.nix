#
# A powerful AI coding agent. Built for the terminal.
# src: https://github.com/charmbracelet/crush
#

{
  xdg.configFile."mise/conf.d/crush.toml".source = ./.config/mise/conf.d/crush.toml;
  xdg.configFile."crush/.crush.json".source = ./.config/crush/crush.json;
  xdg.configFile."crush/commands" = {
    source = ../.config/ai/prompts;
    recursive = true;
  };
}
