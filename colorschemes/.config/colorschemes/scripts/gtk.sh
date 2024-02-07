#!/usr/bin/env bash

set -euo pipefail

gtk_font="${1:-Noto Sans 13}"
gtk_theme="${2:-Windows-10-Dark}"
icon_theme="${3:-Zafiro}"
cursor_theme="${4:-Qogirr}"

# apply gtk theme, icons, cursor & fonts
xfconf-query -c xsettings -p /Gtk/FontName -s "${gtk_font}"
xfconf-query -c xsettings -p /Net/ThemeName -s "${gtk_theme}"
xfconf-query -c xsettings -p /Net/IconThemeName -s "${icon_theme}"
xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "${cursor_theme}"

# inherit cursor theme
if [[ -f "${HOME}/.icons/default/index.theme" ]]; then
	sed -i -e "s/Inherits=.*/Inherits=${cursor_theme}/g" "${HOME}"/.icons/default/index.theme
fi
