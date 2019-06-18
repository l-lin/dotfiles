#!/bin/bash

set -e
set -x

sudo apt-get update
# Install additional commands
sudo apt-get install build-essential cmake git zsh fortune cowsay colordiff vim exuberant-ctags tmux python-pip python-dev ruby-dev ruby htop xclip httpie silversearcher-ag nfs-common net-tools lm-sensors libgtop network-manager-openvpn openvpn network-manager-openvpn-gnome curl nnn jq ubuntu-restricted-extras libpqdev
echo "[-] Switch zsh as default shell"
chsh -s $(which zsh)

echo "[-] Instaling oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
