#!/usr/bin/env bash

set -euo pipefail

colorscheme="${1:-kanagawa}"

file_path="${HOME}/.config/tridactyl/tridactylrc"

if [[ -f "${file_path}" ]]; then
	sed -i --follow-symlinks "s/^colors .*/colors ${colorscheme}/" "${file_path}"
fi
