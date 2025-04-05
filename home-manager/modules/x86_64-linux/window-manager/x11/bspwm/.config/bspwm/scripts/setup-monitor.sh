#!/usr/bin/env bash
#
# Single monitor for everything, so I'm focus on a single monitor and not be
# distracted with the laptop monitor.
# src: https://wiki.archlinux.org/title/Bspwm
#

# bspwm existence check, otherwise exit.
pgrep bspwm > /dev/null || exit 0

# To get the list of monitor names, use the cmd `bspc query -M --names`.
laptop_monitor='eDP-1'
external_monitor='HDMI-1'

monitor_switch() {
  local from=${1}
  local to=${2}

  # Move all desktops to the other monitor.
  for desktop in $(bspc query --desktops --monitor "${from}"); do
    bspc desktop "${desktop}" --to-monitor "${to}"
  done

  # Remove the obsolete monitor.
  bspc monitor "${from}" --remove >/dev/null

  # Reset monitor desktops, so that I always have the default desktops.
  bspc monitor "${to}" --reset-desktops 1 2 3 4 5
}

if xrandr | grep -q "${external_monitor} connected"; then
  monitor_switch "${laptop_monitor}" "${external_monitor}"
  # Disable Laptop monitor, so that I can focus on a single monitor.
  xrandr --output "${laptop_monitor}" --off
else
  monitor_switch "${external_monitor}" "${laptop_monitor}"
  # Re-enable Laptop monitor.
  xrandr --output "${laptop_monitor}" --auto
fi

