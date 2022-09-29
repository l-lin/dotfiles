#!/usr/bin/env bash

set -eu

read -p "Install ubuntu packages? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo apt-get update

  echo "[-] Installing lots of stuffs"
  # install additional commands
  sudo apt install build-essential cmake git zsh colordiff exuberant-ctags tmux ruby-dev ruby htop xclip silversearcher-ag nfs-common net-tools lm-sensors network-manager-openvpn openvpn network-manager-openvpn-gnome curl jq ubuntu-restricted-extras software-properties-common gnome-tweaks preload chrome-gnome-shell libssl-dev bison libpq-dev
  # packages for pythons
  # zlib: deals with "No module named 'zlib'
  # libffi: deals with "No module named '_ctypes'
  # libbz2: deals with "No module named '_bz2'
  sudo apt install python-setuptools \
    zlib1g-dev \
    libffi-dev \
    libbz2-dev

  # for Ubuntu 22, we need this package to run AppImages
  sudo apt install libfuse2

  #echo "[-] Installing OBS for live stream: https://obsproject.com"
  #sudo add-apt-repository ppa:obsproject/obs-studio
  #sudo apt update
  #sudo apt install obs-studio
  # for RTSP server: https://github.com/iamscottxu/obs-rtspserver

  # to resolve *.localhost automatically to 127.0.0.1
  echo "[-] Installing nss-myhostname: https://man7.org/linux/man-pages/man8/nss-myhostname.8.html "
  sudo apt install libnss-myhostname

  echo "[-] Installing jo: https://github.com/jpmens/jo"
  sudo apt install jo

  echo "[-] Installing pgcli: https://github.com/dbcli/pgcli"
  sudo apt install pgcli

  echo "[-] Installing podman: https://github.com/containers/podman"
  sudo apt install podman

  echo "[-] Installing ripgrep: https://github.com/BurntSushi/ripgrep"
  sudo apt install ripgrep

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

