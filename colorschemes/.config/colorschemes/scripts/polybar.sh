#!/usr/bin/env bash

set -euo pipefail

colorscheme="${1:-kanagawa}"
polybar_font="${2:-JetBrains Mono:size=11;3}"

openbox_dir="${HOME}/.config/openbox"
polybar_dir="${openbox_dir}/themes/shared/polybar"

# modify polybar launch script
sed -i -e "s/STYLE=.*/STYLE=\"${colorscheme}\"/g" "${openbox_dir}"/themes/polybar.sh

# apply default theme fonts
sed -i -e "s/font-0 = .*/font-0 = \"${polybar_font}\"/g" "${polybar_dir}"/config.ini

# rewrite colors file
sed -i --follow-symlinks "s~colorschemes/\(.*\)\.ini~colorschemes/${colorscheme}.ini~" "${polybar_dir}"/config.ini
