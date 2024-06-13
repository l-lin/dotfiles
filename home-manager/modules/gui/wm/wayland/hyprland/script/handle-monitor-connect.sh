#!/bin/sh
# Move workspace to specific monitors.
# https://wiki.hyprland.org/FAQ/#how-do-i-move-my-favorite-workspaces-to-a-new-monitor-when-i-plug-it-in

handle() {
  case $1 in monitoradded*)
    hyprctl dispatch moveworkspacetomonitor "1 0"
    hyprctl dispatch moveworkspacetomonitor "2 1"
    hyprctl dispatch moveworkspacetomonitor "3 1"
    hyprctl dispatch moveworkspacetomonitor "4 1"
    hyprctl dispatch moveworkspacetomonitor "5 1"
  esac
}

socat - "UNIX-CONNECT:${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock" \
  | while read -r line; do \
    handle "$line"; \
  done
