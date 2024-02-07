#!/usr/bin/env bash

set -euo pipefail

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
openbox_dir="${XDG_CONFIG_HOME}/openbox"
scripts_dir="${XDG_CONFIG_HOME}/colorschemes/scripts"

## Theme ------------------------------------
theme_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
colorscheme="${theme_dir##*/}"

source "${openbox_dir}"/themes/"${colorscheme}"/theme.bash

altbackground="$(pastel color "${background}" | pastel lighten "${light_value}" | pastel format hex)"

# Create Theme File -------------------------
create_file() {
	local theme_file="${openbox_dir}/themes/.current"
	if [[ ! -f "$theme_file" ]]; then
		touch "${theme_file}"
	fi
	echo "$colorscheme" > "${theme_file}"
}

# Notify User -------------------------------
notify_user() {
	dunstify -u normal -h string:x-dunst-stack-tag:applytheme -i /usr/share/archcraft/icons/dunst/themes.png "Applying Style : $colorscheme"
}

## Execute Scripts ---------------------------
notify_user
create_file

bash "${scripts_dir}/wallpaper.sh" "${wallpaper}" "${wallpaper_color}"
bash "${scripts_dir}/polybar.sh" "${colorscheme}" "${polybar_font}"
bash "${scripts_dir}/rofi.sh" "${colorscheme}" "${rofi_font}" "${rofi_icon}"
bash "${scripts_dir}/alacritty.sh" "${colorscheme}"
bash "${scripts_dir}/geany.sh" "${geany_colors}" "${geany_font}"
bash "${scripts_dir}/gtk.sh" "${gtk_font}" "${gtk_theme}" "${icon_theme}" "${cursor_theme}"
bash "${scripts_dir}/openbox.sh" "${ob_theme}" "${ob_layout}" "${ob_font}" "${ob_font_size}" "${ob_menu}" "${ob_margin_t}" "${ob_margin_b}" "${ob_margin_l}" "${ob_margin_r}"
bash "${scripts_dir}/dunst.sh" "${background}" "${foreground}" "${altbackground}"
bash "${scripts_dir}/change-terminal.sh"
bash "${scripts_dir}/bat.sh" "${bat_theme}"
bash "${scripts_dir}/delta.sh" "${delta_theme}"
bash "${scripts_dir}/nvim.sh" "${nvim_colorscheme}" "${nvim_background}"
bash "${scripts_dir}/tmux.sh" "${colorscheme}"
bash "${scripts_dir}/tridactyl.sh" "${colorscheme}"
bash "${scripts_dir}/zsh.sh" "${colorscheme}"

# launch polybar
bash "${openbox_dir}"/themes/polybar.sh

# fix cursor theme (run it in the end)
xsetroot -cursor_name left_ptr

