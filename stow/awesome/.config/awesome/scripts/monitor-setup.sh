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
connected_monitors=$(xrandr | grep " connected")

if [[ $(echo "${connected_monitors}" | wc -l) -gt 1 ]]; then
  external_monitor=$(echo "${connected_monitors}" | grep -v "${laptop_monitor}" | awk '{ print $1 }')

  # If the external monitor is not displayed, then we should display it before
  # disabling the laptop monitor.
  if ! echo "${connected_monitors}" | grep -q '1920'; then
    xrandr --output "${external_monitor}" --auto
  fi

  # Disable Laptop monitor, so that I can focus on a single monitor.
  xrandr --output "${laptop_monitor}" --off
else
  # Re-enable Laptop monitor.
  xrandr --output "${laptop_monitor}" --auto
fi

