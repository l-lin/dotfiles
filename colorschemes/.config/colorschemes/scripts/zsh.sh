#!/usr/bin/env bash

set -euo pipefail

colorscheme="${1:-kanagawa}"

file_path="${HOME}/.config/zsh/.zsh_colorscheme"

if [[ -f "${file_path}" ]]; then
	sed -i --follow-symlinks "s/^export ZSH_COLORSCHEME='.*'/export ZSH_COLORSCHEME='${colorscheme}'/" "${file_path}"
fi
