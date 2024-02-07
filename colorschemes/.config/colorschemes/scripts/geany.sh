#!/usr/bin/env bash

set -euo pipefail

geany_colors="${1:-arc.conf}"
geany_font="${2:-JetBrains Mono 10}"

geany_dir="${HOME}/.config/geany"

sed -i "${geany_dir}"/geany.conf \
	-e "s/color_scheme=.*/color_scheme=${geany_colors}/g" \
	-e "s/editor_font=.*/editor_font=${geany_font}/g"
