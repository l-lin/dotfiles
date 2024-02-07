#!/usr/bin/env bash

set -euo pipefail

colorscheme="${1:-kanagawa}"
rofi_font="${2:-Iosevka 10}"
rofi_icon="${3:-Zafiro}"

openbox_dir="${HOME}/.config/openbox"
rofi_dir="${HOME}/.config/rofi"

# modify rofi scripts
sed -i -e "s/STYLE=.*/STYLE=\"${colorscheme}\"/g" \
	"${openbox_dir}"/scripts/rofi-askpass \
	"${openbox_dir}"/scripts/rofi-bluetooth \
	"${openbox_dir}"/scripts/rofi-launcher \
	"${openbox_dir}"/scripts/rofi-music \
	"${openbox_dir}"/scripts/rofi-powermenu \
	"${openbox_dir}"/scripts/rofi-runner \
	"${openbox_dir}"/scripts/rofi-screenshot

# apply default theme fonts
if [[ -f "${rofi_dir}/themes/shared/rofi/fonts.rasi" ]]; then
  sed -i --follow-symlinks -e "s/font:.*/font: \"$rofi_font\";/g" "${openbox_dir}"/themes/shared/rofi/fonts.rasi
fi

# rewrite colors file
for f in "${openbox_dir}/themes/shared/rofi/"*.rasi; do
	sed -i --follow-symlinks -e "s~colorschemes/\(.*\)\.rasi~colorschemes/${colorscheme}\.rasi~" "${f}"
done

# modify icon theme
if [[ -f "${rofi_dir}"/config.rasi ]]; then
	sed -i --follow-symlinks -e "s/icon-theme:.*/icon-theme: \"${rofi_icon}\";/g" "${rofi_dir}"/config.rasi
fi

