#!/usr/bin/env bash

set -euo pipefail

colorscheme="${1:-kanagawa}"

alacritty_config_file_path="${HOME}/.config/alacritty/alacritty.toml"

if [[ -f "${alacritty_config_file_path}" ]]; then
	sed -i --follow-symlinks "s~colorschemes/\(.*\)\.toml~colorschemes/${colorscheme}.toml~" "${alacritty_config_file_path}"
fi
