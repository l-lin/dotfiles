#!/usr/bin/env bash

set -euo pipefail

colorscheme="${1:-kanagawa}"
background="${2:-dark}"

options_file_path="${HOME}/.config/nvim/lua/config/options.lua"

if [[ -f "${options_file_path}" ]]; then
	sed -i --follow-symlinks "s/^vim.o.bg = \"\(dark\|light\)\"$/vim.o.bg = \"${background}\"/" "${options_file_path}"
fi

colorscheme_file_path="${HOME}/.config/nvim/lua/plugins/colorscheme.lua"

if [[ -f "${colorscheme_file_path}" ]]; then
	sed -i --follow-symlinks "s/    colorscheme = \".*\"/    colorscheme = \"${colorscheme}\"/" "${colorscheme_file_path}"
fi
