#!/usr/bin/env bash

set -euo pipefail

colorscheme="${1:-kanagawa}"

tmux_file_path="${HOME}/.tmux.conf"

if [[ -f "${tmux_file_path}" ]]; then
	sed -i --follow-symlinks "s/^set -g @tmux-colorscheme '.*'/set -g @tmux-colorscheme '${colorscheme}'/" "${tmux_file_path}"
	tmux source "${tmux_file_path}"
fi
