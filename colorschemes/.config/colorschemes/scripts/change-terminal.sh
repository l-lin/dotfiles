#!/usr/bin/env bash

set -euo pipefail

openbox_dir="${HOME}/.config/openbox"

change_terminal() {
	local file_path="${1}"

	if [[ -f "${file_path}" ]]; then
		sed -i --follow-symlinks "s/xfce4-terminal/alacritty/g" "${file_path}"
	fi
}

change_terminal "${openbox_dir}/rc.xml"
change_terminal "${openbox_dir}/menu-minimal.xml"
change_terminal "${openbox_dir}/menu-glyphs.xml"
change_terminal "${openbox_dir}/menu-icons.xml"
change_terminal "${openbox_dir}/menu-simple.xml"
change_terminal "${HOME}/.config/networkmanager-dmenu/config.ini"
change_terminal "${HOME}/.config/geany/geany.conf"

