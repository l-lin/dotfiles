#!/usr/bin/env bash
# Play or pause song in Spotify.
# src: https://community.spotify.com/t5/Desktop-Linux/Basic-controls-via-command-line/td-p/4295625

set -eu

spotify_pid="$(pidof -s spotify || pidof -s .spotify-wrapped)"
if [[ -n "${spotify_pid}" ]]; then
  dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
fi
