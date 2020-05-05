#!/bin/bash

set -e
set -x

sudo apt-get update

echo "[-] Installing lots of stuffs"
# Install additional commands
sudo apt install build-essential cmake git zsh colordiff exuberant-ctags tmux python2-dev ruby-dev ruby htop xclip httpie silversearcher-ag nfs-common net-tools lm-sensors network-manager-openvpn openvpn network-manager-openvpn-gnome curl nnn jq ubuntu-restricted-extras software-properties-common python3-dev python3-pip python3-distutils gnome-tweak-tool preload chrome-gnome-shell

echo "[-] Installing ubuntu arc theme"
sudo apt install arc-theme

echo "[-] Switch zsh as default shell"
chsh -s $(which zsh)

echo "[-] Instaling oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

