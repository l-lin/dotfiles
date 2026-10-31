#
# Accelerate your entire organization with custom AI agents.
# src: https://dust.tt/
#

{ pkgs, ... }: {
  xdg.configFile."mise/conf.d/dust-cli.toml".source = ./.config/mise/conf.d/dust-cli.toml;

  home.packages = with pkgs; [
    (writeShellScriptBin "dust-cli" ''
#!/usr/bin/env bash
#
# Wrapper script to launch opencode-ai, as its name conflicts with the other opencode name.
#

set -euo pipefail

BIN_PATH="$(mise bin-paths | grep dust)/dust"

if [ ! -x "$BIN_PATH" ]; then
  echo "[dust] ERROR: Binary not found at $BIN_PATH" >&2
  exit 1
fi

"$BIN_PATH" "$@"
'')
  ];
}
