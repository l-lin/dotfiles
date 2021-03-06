#!/usr/bin/env bash

set -eu

read -p "Install ubuntu packages? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo apt-get update

  echo "[-] Installing lots of stuffs"
  # Install additional commands
  sudo apt install build-essential cmake git zsh colordiff exuberant-ctags tmux ruby-dev ruby htop xclip httpie silversearcher-ag nfs-common net-tools lm-sensors network-manager-openvpn openvpn network-manager-openvpn-gnome curl nnn jq ubuntu-restricted-extras software-properties-common gnome-tweak-tool preload chrome-gnome-shell libssl-dev bison python-setuptools libpq-dev

  echo "[-] Installing some ubuntu apps"
  sudo apt install gnome-shell-pomodoro alacarte peek

  echo "[-] Installing ubuntu arc theme"
  sudo apt install arc-theme

  echo "[-] Switch zsh as default shell"
  chsh -s $(which zsh)

  echo "[-] Instaling oh-my-zsh"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

  echo "[-] Finished installing ubuntu stuffs, switching to ZSH shell"
fi

