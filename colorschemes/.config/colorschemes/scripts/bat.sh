#!/usr/bin/env bash

set -euo pipefail

colorscheme="${1:-Catppuccin-mocha}"

file_path="${HOME}/.config/bat/config"

if [[ -f "${file_path}" ]]; then
	sed -i --follow-symlinks "s/^--theme=\".*\"/--theme=\"${colorscheme}\"/" "${file_path}"
fi
