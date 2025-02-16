#!/usr/bin/env bash
#
# Single monitor for everything, so I'm focus on a single monitor and not be
# distracted with the laptop monitor.
#

# To get the list of monitor names, use the cmd:
#
# ```bassh
# xrandr | grep " connected " | awk '{ print$1 }'
# ```
laptop_monitor='eDP-1'
external_monitor='HDMI-1'

if xrandr | grep -q "${external_monitor} connected"; then
  # Disable Laptop monitor, so that I can focus on a single monitor.
  xrandr --output "${laptop_monitor}" --off
else
  # Re-enable Laptop monitor.
  xrandr --output "${laptop_monitor}" --auto
fi

date > /tmp/monitor.log

