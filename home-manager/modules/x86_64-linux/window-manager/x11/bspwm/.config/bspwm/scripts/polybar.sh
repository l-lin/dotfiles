#!/usr/bin/env bash

killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# bspmwm does not reset the padding, so we need to manually call it so that
# polybar will automatically add the correct padding.
bspc config top_padding 24

polybar -q main -c "${XDG_CONFIG_HOME:-${HOME}/.config}/polybar/config.ini"
