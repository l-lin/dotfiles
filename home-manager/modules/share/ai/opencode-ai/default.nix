#
# A powerful AI coding agent. Built for the terminal.
# src: https://github.com/opencode-ai/opencode
# WARNING: Not the same as https://opencode.ai/! They share the same binary name though...
#

{ pkgs, ... }: {
  xdg.configFile."mise/conf.d/opencode-ai.toml".source = ./.config/mise/conf.d/opencode-ai.toml;
  xdg.configFile."opencode/.opencode.json".source = ./.config/opencode/.opencode.json;
  xdg.configFile."opencode/commands" = {
    source = ../.config/ai/prompts;
    recursive = true;
  };

  home.packages = with pkgs; [
    (writeShellScriptBin "opencode-ai" ''
#!/usr/bin/env bash
#
# Wrapper script to launch opencode-ai, as its name conflicts with the other opencode name.
#

set -euo pipefail

BIN_PATH="$(mise bin-paths | grep go-github-com-opencode-ai-opencode)/opencode"

if [ ! -x "$BIN_PATH" ]; then
  echo "[opencode-ai] ERROR: Binary not found at $BIN_PATH" >&2
  exit 1
fi

"$BIN_PATH" "$@"
'')
  ];
}
