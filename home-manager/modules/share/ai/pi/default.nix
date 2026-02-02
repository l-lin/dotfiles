#
# AI agent toolkit: coding agent CLI, unified LLM API, TUI & web UI libraries, Slack bot, vLLM pods
# src: https://github.com/badlogic/pi-mono
#

{ config, symlinkRoot, ... }: {
  xdg.configFile."mise/conf.d/pi.toml".source = ./.config/mise/conf.d/pi.toml;

  home.file = {
    # pi may edit the settings.json, so let allow write on this file.
    ".pi/agent/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${symlinkRoot}/home-manager/modules/share/ai/pi/.pi/agent/settings.json";
    ".pi/agent/keybindings.json".source = ./.pi/agent/keybindings.json;
    ".pi/agent/APPEND_SYSTEM.md".source = ../.config/ai/system-prompt.md;
  };
}
