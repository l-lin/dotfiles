#!/usr/bin/env bash

## Theme ------------------------------------
TDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
THEME="${TDIR##*/}"

source "$HOME"/.config/openbox-themes/themes/"$THEME"/theme.bash
altbackground="$(pastel color $background | pastel lighten $light_value | pastel format hex)"
altforeground="$(pastel color $foreground | pastel darken $dark_value | pastel format hex)"

## Directories ------------------------------
PATH_CONF="$HOME/.config"
PATH_TERM="$PATH_CONF/alacritty"
PATH_DUNST="$PATH_CONF/dunst"
PATH_GEANY="$PATH_CONF/geany"
PATH_OBOX="$PATH_CONF/openbox"
PATH_OBTS="$PATH_CONF/openbox-themes"
PATH_PBAR="$PATH_OBTS/themes/$THEME/polybar"
PATH_ROFI="$PATH_OBTS/themes/$THEME/rofi"
PATH_XFCE="$PATH_CONF/xfce4/terminal"

## Wallpaper ---------------------------------
apply_wallpaper() {
	for head in {0..10}; do
		nitrogen --head=$head --save --set-centered "$wallpaper" --set-color="${wallpaper_color}" &>/dev/null
	done
}

## Polybar -----------------------------------
apply_polybar() {
	# modify polybar launch script
	sed -i -e "s/STYLE=.*/STYLE=\"$THEME\"/g" ${PATH_OBTS}/themes/polybar.sh

	# apply default theme fonts
	sed -i -e "s/font-0 = .*/font-0 = \"$polybar_font\"/g" ${PATH_PBAR}/config.ini

	# rewrite colors file
	cat >${PATH_PBAR}/colors.ini <<-EOF
		[color]

		BACKGROUND = ${background}
		FOREGROUND = ${foreground}
		ALTBACKGROUND = ${altbackground}
		ALTFOREGROUND = ${altforeground}
		ACCENT = ${accent}

		BLACK = ${color_black}
		RED = ${color_red}
		GREEN = ${color_green}
		YELLOW = ${color_yellow}
		BLUE = ${color_blue}
		MAGENTA = ${color_magenta}
		CYAN = ${color_cyan}
		WHITE = ${color_white}
		ALTBLACK = ${color_altblack}
		ALTRED = ${color_altred}
		ALTGREEN = ${color_altgreen}
		ALTYELLOW = ${color_altyellow}
		ALTBLUE = ${color_altblue}
		ALTMAGENTA = ${color_altmagenta}
		ALTCYAN = ${color_altcyan}
		ALTWHITE = ${color_altwhite}
	EOF

	# launch polybar
	bash ${PATH_OBTS}/themes/polybar.sh
}

# Rofi --------------------------------------
apply_rofi() {
	# modify rofi scripts
	sed -i -e "s/STYLE=.*/STYLE=\"$THEME\"/g" \
		${PATH_OBTS}/scripts/askpass \
		${PATH_OBTS}/scripts/launcher \
		${PATH_OBTS}/scripts/music \
		${PATH_OBTS}/scripts/powermenu \
		${PATH_OBTS}/scripts/runner \
		${PATH_OBTS}/scripts/screenshot

	# apply default theme fonts
	sed -i -e "s/font:.*/font: \"$rofi_font\";/g" ${PATH_ROFI}/shared/fonts.rasi

	# rewrite colors file
	cat >${PATH_ROFI}/shared/colors.rasi <<-EOF
		* {
		    background:     ${background};
		    background-alt: ${altbackground};
		    foreground:     ${foreground};
		    selected:       ${accent};
		    active:         ${color_green};
		    urgent:         ${color_red};
		}
	EOF

	# modify icon theme
	if [[ -f "$PATH_CONF"/rofi/config.rasi ]]; then
		sed -i -e "s/icon-theme:.*/icon-theme: \"$rofi_icon\";/g" ${PATH_CONF}/rofi/config.rasi
	fi
}

# Network Menu ------------------------------
apply_netmenu() {
	if [[ -f "$PATH_CONF"/networkmanager-dmenu/config.ini ]]; then
		sed -i -e "s#dmenu_command = .*#dmenu_command = rofi -dmenu -theme $PATH_ROFI/networkmenu.rasi#g" ${PATH_CONF}/networkmanager-dmenu/config.ini
	fi
}

# Terminal ----------------------------------
apply_terminal() {
	# alacritty : fonts
	sed -i ${PATH_TERM}/fonts.yml \
		-e "s/family: .*/family: \"$terminal_font_name\"/g" \
		-e "s/size: .*/size: $terminal_font_size/g"

	# alacritty : colors
	cat >${PATH_TERM}/colors.yml <<-_EOF_
		## Colors configuration
		colors:
		  # Default colors
		  primary:
		    background: '${background}'
		    foreground: '${foreground}'

		  # Normal colors
		  normal:
		    black:   '${color_black}'
		    red:     '${color_red}'
		    green:   '${color_green}'
		    yellow:  '${color_yellow}'
		    blue:    '${color_blue}'
		    magenta: '${color_magenta}'
		    cyan:    '${color_cyan}'
		    white:   '${color_white}'

		  # Bright colors
		  bright:
		    black:   '${color_altblack}'
		    red:     '${color_altred}'
		    green:   '${color_altgreen}'
		    yellow:  '${color_altyellow}'
		    blue:    '${color_altblue}'
		    magenta: '${color_altmagenta}'
		    cyan:    '${color_altcyan}'
		    white:   '${color_altwhite}'
	_EOF_

	# xfce terminal : fonts & colors
	sed -i ${PATH_XFCE}/terminalrc \
		-e "s/FontName=.*/FontName=$terminal_font_name $terminal_font_size/g" \
		-e "s/ColorBackground=.*/ColorBackground=${background}/g" \
		-e "s/ColorForeground=.*/ColorForeground=${foreground}/g" \
		-e "s/ColorCursor=.*/ColorCursor=${foreground}/g" \
		-e "s/ColorPalette=.*/ColorPalette=${color_black};${color_red};${color_green};${color_yellow};${color_blue};${color_magenta};${color_cyan};${color_white};${color_altblack};${color_altred};${color_altgreen};${color_altyellow};${color_altblue};${color_altmagenta};${color_altcyan};${color_altwhite}/g"
}

# Geany -------------------------------------
apply_geany() {
	sed -i ${PATH_GEANY}/geany.conf \
		-e "s/color_scheme=.*/color_scheme=$geany_colors/g" \
		-e "s/editor_font=.*/editor_font=$geany_font/g"
}

# Appearance --------------------------------
apply_appearance() {
	# apply gtk theme, icons, cursor & fonts
	xfconf-query -c xsettings -p /Gtk/FontName -s "$gtk_font"
	xfconf-query -c xsettings -p /Net/ThemeName -s "$gtk_theme"
	xfconf-query -c xsettings -p /Net/IconThemeName -s "$icon_theme"
	xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "$cursor_theme"

	# inherit cursor theme
	if [[ -f "$HOME"/.icons/default/index.theme ]]; then
		sed -i -e "s/Inherits=.*/Inherits=$cursor_theme/g" "$HOME"/.icons/default/index.theme
	fi
}

# Openbox -----------------------------------
apply_obconfig() {
	namespace="http://openbox.org/3.4/rc"
	config="$PATH_OBOX/rc.xml"

	# Theme
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:name' -v "$ob_theme" "$config"

	# Title
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:titleLayout' -v "$ob_layout" "$config"

	# Fonts
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="ActiveWindow"]/a:name' -v "$ob_font" "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="ActiveWindow"]/a:size' -v "$ob_font_size" "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="ActiveWindow"]/a:weight' -v Bold "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="ActiveWindow"]/a:slant' -v Normal "$config"

	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="InactiveWindow"]/a:name' -v "$ob_font" "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="InactiveWindow"]/a:size' -v "$ob_font_size" "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="InactiveWindow"]/a:weight' -v Normal "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="InactiveWindow"]/a:slant' -v Normal "$config"

	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="MenuHeader"]/a:name' -v "$ob_font" "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="MenuHeader"]/a:size' -v "$ob_font_size" "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="MenuHeader"]/a:weight' -v Bold "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="MenuHeader"]/a:slant' -v Normal "$config"

	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="MenuItem"]/a:name' -v "$ob_font" "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="MenuItem"]/a:size' -v "$ob_font_size" "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="MenuItem"]/a:weight' -v Normal "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="MenuItem"]/a:slant' -v Normal "$config"

	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="ActiveOnScreenDisplay"]/a:name' -v "$ob_font" "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="ActiveOnScreenDisplay"]/a:size' -v "$ob_font_size" "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="ActiveOnScreenDisplay"]/a:weight' -v Bold "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="ActiveOnScreenDisplay"]/a:slant' -v Normal "$config"

	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="InactiveOnScreenDisplay"]/a:name' -v "$ob_font" "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="InactiveOnScreenDisplay"]/a:size' -v "$ob_font_size" "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="InactiveOnScreenDisplay"]/a:weight' -v Normal "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:theme/a:font[@place="InactiveOnScreenDisplay"]/a:slant' -v Normal "$config"

	# Openbox Menu Style
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:menu/a:file' -v "$ob_menu" "$config"

	# Margins
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:margins/a:top' -v ${ob_margin_t} "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:margins/a:bottom' -v ${ob_margin_b} "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:margins/a:left' -v ${ob_margin_l} "$config"
	xmlstarlet ed -L -N a="$namespace" -u '/a:openbox_config/a:margins/a:right' -v ${ob_margin_r} "$config"

	# TODO: remove shortcuts to `C-A-m` and `C-S-R` and `W-l`
	# TODO: replace betterlockscreen --lock shortcut from `C-A-l` to `W-l`

	# Reload Openbox Config
	openbox --reconfigure
}

# Dunst -------------------------------------
apply_dunst() {
	# modify dunst config
	sed -i ${PATH_DUNST}/dunstrc \
		-e "s/width = .*/width = $dunst_width/g" \
		-e "s/height = .*/height = $dunst_height/g" \
		-e "s/offset = .*/offset = $dunst_offset/g" \
		-e "s/origin = .*/origin = $dunst_origin/g" \
		-e "s/font = .*/font = $dunst_font/g" \
		-e "s/frame_width = .*/frame_width = $dunst_border/g" \
		-e "s/separator_height = .*/separator_height = $dunst_separator/g" \
		-e "s/line_height = .*/line_height = $dunst_separator/g"

	# modify colors
	sed -i '/urgency_low/Q' ${PATH_DUNST}/dunstrc
	cat >>${PATH_DUNST}/dunstrc <<-_EOF_
		[urgency_low]
		timeout = 2
		background = "${background}"
		foreground = "${foreground}"
		frame_color = "${altbackground}"

		[urgency_normal]
		timeout = 5
		background = "${background}"
		foreground = "${foreground}"
		frame_color = "${altbackground}"

		[urgency_critical]
		timeout = 0
		background = "${background}"
		foreground = "${color1}"
		frame_color = "${color1}"
	_EOF_

	# restart dunst
	pkill dunst && dunst &
}

# Plank -------------------------------------
apply_plank() {
	# create temporary config file
	cat >"$HOME"/.cache/plank.conf <<-_EOF_
		[dock1]
		alignment='center'
		auto-pinning=true
		current-workspace-only=false
		dock-items=['xfce-settings-manager.dockitem', 'Alacritty.dockitem', 'thunar.dockitem', 'firefox.dockitem', 'geany.dockitem']
		hide-delay=0
		hide-mode='$plank_hmode'
		icon-size=$plank_icon_size
		items-alignment='center'
		lock-items=false
		monitor=''
		offset=$plank_offset
		pinned-only=false
		position='$plank_position'
		pressure-reveal=false
		show-dock-item=false
		theme='$plank_theme'
		tooltips-enabled=true
		unhide-delay=0
		zoom-enabled=true
		zoom-percent=$plank_zoom_percent
	_EOF_

	# apply config and reload plank
	cat "$HOME"/.cache/plank.conf | dconf load /net/launchpad/plank/docks/
}

# Compositor --------------------------------
apply_compositor() {
	picom_cfg="$PATH_CONF/picom.conf"

	# modify picom config
	sed -i "$picom_cfg" \
		-e "s/backend = .*/backend = \"$picom_backend\";/g" \
		-e "s/corner-radius = .*/corner-radius = $picom_corner;/g" \
		-e "s/shadow-radius = .*/shadow-radius = $picom_shadow_r;/g" \
		-e "s/shadow-opacity = .*/shadow-opacity = $picom_shadow_o;/g" \
		-e "s/shadow-offset-x = .*/shadow-offset-x = $picom_shadow_x;/g" \
		-e "s/shadow-offset-y = .*/shadow-offset-y = $picom_shadow_y;/g" \
		-e "s/method = .*/method = \"$picom_blur_method\";/g" \
		-e "s/strength = .*/strength = $picom_blur_strength;/g"
}

# Create Theme File -------------------------
create_file() {
	theme_file="$PATH_OBTS/themes/.current"
	if [[ ! -f "$theme_file" ]]; then
		touch ${theme_file}
	fi
	echo "$THEME" >${theme_file}
}

# Notify User -------------------------------
notify_user() {
	dunstify -u normal -h string:x-dunst-stack-tag:applytheme -i /usr/share/archcraft/icons/dunst/themes.png "Applying Style : $THEME"
}

# Change default terminal in keymaps -------------------------------
change_terminal() {
	local file_path="${1}"

	if [[ -f "${file_path}" ]]; then
		# sed -i "s/alacritty/xfce4-terminal/g" "${file_path}"
		sed -i "s/xfce4-terminal/alacritty/g" "${file_path}"
	fi
}
apply_change_terminal() {
	change_terminal "${PATH_OBOX}/rc.xml"
	change_terminal "${PATH_OBOX}/menu-minimal.xml"
	change_terminal "${PATH_OBOX}/menu-glyphs.xml"
	change_terminal "${PATH_OBOX}/menu-icons.xml"
	change_terminal "${PATH_OBOX}/menu-simple.xml"
	change_terminal "${PATH_CONF}/networkmanager-dmenu/config.ini"
	change_terminal "${PATH_CONF}/geany/geany.conf"
}

change_tmux_background() {
	local file_path="${HOME}/.tmux.conf"

	if [[ -f "${file_path}" ]]; then
		sed -i --follow-symlinks "s/^set -g @tmux-colorscheme '.*'/set -g @tmux-colorscheme '${THEME}'/" "${file_path}"
		tmux source "${file_path}"
	fi
}

change_nvim_background() {
	local options_file_path="${HOME}/.config/nvim/lua/config/options.lua"

	if [[ -f "${options_file_path}" ]]; then
		sed -i --follow-symlinks "s/^vim.o.bg = \"\(dark\|light\)\"$/vim.o.bg = \"${nvim_background}\"/" "${options_file_path}"
	fi

	local colorscheme_file_path="${HOME}/.config/nvim/lua/plugins/colorscheme.lua"

	if [[ -f "${colorscheme_file_path}" ]]; then
		sed -i --follow-symlinks "s/    colorscheme = \".*\"/    colorscheme = \"${nvim_colorscheme}\"/" "${colorscheme_file_path}"
	fi
}

change_zsh_background() {
	local file_path="${HOME}/.zshenv"

	if [[ -f "${file_path}" ]]; then
		sed -i --follow-symlinks "s/^export ZSH_THEME_BG='.*'/export ZSH_THEME_BG='${background}'/" "${file_path}"
		sed -i --follow-symlinks "s/^export ZSH_THEME_FG='.*'/export ZSH_THEME_FG='${foreground}'/" "${file_path}"
		sed -i --follow-symlinks "s/^export ZSH_THEME_BLACK='.*'/export ZSH_THEME_BLACK='${color_black}'/" "${file_path}"
		sed -i --follow-symlinks "s/^export ZSH_THEME_RED='.*'/export ZSH_THEME_RED='${color_red}'/" "${file_path}"
		sed -i --follow-symlinks "s/^export ZSH_THEME_GREEN='.*'/export ZSH_THEME_GREEN='${color_green}'/" "${file_path}"
		sed -i --follow-symlinks "s/^export ZSH_THEME_YELLOW='.*'/export ZSH_THEME_YELLOW='${color_yellow}'/" "${file_path}"
		sed -i --follow-symlinks "s/^export ZSH_THEME_BLUE='.*'/export ZSH_THEME_BLUE='${color_blue}'/" "${file_path}"
		sed -i --follow-symlinks "s/^export ZSH_THEME_MAGENTA='.*'/export ZSH_THEME_MAGENTA='${color_magenta}'/" "${file_path}"
		sed -i --follow-symlinks "s/^export ZSH_THEME_CYAN='.*'/export ZSH_THEME_CYAN='${color_cyan}'/" "${file_path}"
		sed -i --follow-symlinks "s/^export ZSH_THEME_WHITE='.*'/export ZSH_THEME_WHITE='${color_white}'/" "${file_path}"
		sed -i --follow-symlinks "s/^export ZSH_THEME_GRAY='.*'/export ZSH_THEME_GRAY='${color_altblack}'/" "${file_path}"
		sed -i --follow-symlinks "s/^export ZSH_THEME_ACCENT='.*'/export ZSH_THEME_ACCENT='${accent}'/" "${file_path}"
	fi
}

change_bat_background() {
	local file_path="${HOME}/.config/bat/config"

	if [[ -f "${file_path}" ]]; then
		sed -i --follow-symlinks "s/^--theme=\".*\"/--theme=\"${bat_theme}\"/" "${file_path}"
	fi
}

change_delta_background() {
	local file_path="${HOME}/.gitconfig"

	if [[ -f "${file_path}" ]]; then
		sed -i --follow-symlinks "s/^  syntax-theme = .*/  syntax-theme = ${delta_theme}/" "${file_path}"
	fi
}

change_tridactyl_background() {
	local file_path="${HOME}/.config/tridactyl/tridactylrc"

	if [[ -f "${file_path}" ]]; then
		sed -i --follow-symlinks "s/^colors .*/colors ${THEME}/" "${file_path}"
	fi
}

apply_change_background() {
	change_tmux_background
	change_nvim_background
	change_zsh_background
	change_bat_background
	change_delta_background
	change_tridactyl_background
}

## Execute Script ---------------------------
notify_user
create_file
apply_wallpaper
apply_polybar
apply_rofi
apply_netmenu
apply_terminal
apply_geany
apply_appearance
apply_obconfig
apply_dunst
apply_plank
apply_compositor

apply_change_terminal
apply_change_background

# fix cursor theme (run it in the end)
xsetroot -cursor_name left_ptr

## ------------------------------------
## Custom startup scripts
## ------------------------------------
# change capslock to ctrl
setxkbmap -layout us -option ctrl:nocaps -variant altgr-intl &
