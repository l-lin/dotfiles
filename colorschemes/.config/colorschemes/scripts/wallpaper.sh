#!/usr/bin/env bash

set -euo pipefail

wallpaper="${1}"
wallpaper_color="${2}"

for head in {0..10}; do
	nitrogen --head="${head}" --save --set-centered "${wallpaper}" --set-color="${wallpaper_color}" &>/dev/null
done
