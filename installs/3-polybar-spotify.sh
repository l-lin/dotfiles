#!/usr/bin/env bash

set -eu

if [ ! -d "${HOME}/apps/polybar-spotify" ]; then
  echo "[-] Installing playerctl to control players"
  yay -S --noconfirm playerctl

  # needs python
  echo "[-] Add symlink to zscroll so it's available from polybar"
  sudo ln -s ${HOME}/.asdf/shims/zscroll /usr/local/bin/zscroll

  echo "[-] Installing polybar-spotify: https://github.com/PrayagS/polybar-spotify"
  git clone https://github.com/PrayagS/polybar-spotify.git ${HOME}/apps/polybar-spotify
else
  echo "[-] polybar-spotify already installed => skipping"
fi

