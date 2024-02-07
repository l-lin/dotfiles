#!/usr/bin/env bash

set -euo pipefail

background="${1:-#1f1f28}"
foreground="${2:-#dcd7ba}"
altbackground="${3:-#363646}"

dunst_dir="${HOME}/.config/dunst"
file_path="${dunst_dir}/dunstrc"

sed -i '/urgency_low/Q' "${file_path}"
cat >> "${file_path}" <<-_EOF_
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
	foreground = "${foreground}"
	frame_color = "${altbackground}"
_EOF_

# restart dunst
pkill dunst && dunst &
