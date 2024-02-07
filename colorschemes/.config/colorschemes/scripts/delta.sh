#!/usr/bin/env bash

set -euo pipefail

colorscheme="${1:-Catppuccin-mocha}"

file_path="${HOME}/.gitconfig"

if [[ -f "${file_path}" ]]; then
	sed -i --follow-symlinks "s/^  syntax-theme = .*/  syntax-theme = ${colorscheme}/" "${file_path}"
fi
