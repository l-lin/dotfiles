#
# AI agent toolkit: coding agent CLI, unified LLM API, TUI & web UI libraries, Slack bot, vLLM pods
# src: https://github.com/badlogic/pi-mono
#

{
  xdg.configFile."mise/conf.d/pi.toml".source = ./.config/mise/conf.d/pi.toml;

  home.file.".pi" = {
    source = ./.pi;
    recursive = true;
  };
}
