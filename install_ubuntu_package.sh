#!/bin/bash

set -e
set -x

# Add neovim repository
sudo add-apt-repository ppa:neovim-ppa/stable
# Add ubuntu arc theme
sudo add-apt-repository ppa:noobslab/themes
sudo add-apt-repository ppa:noobslab/icons

sudo apt-get update

echo "[-] Installing lots of stuffs"
# Install additional commands
sudo apt-get install build-essential cmake git zsh colordiff exuberant-ctags tmux python-pip python-dev ruby-dev ruby htop xclip httpie silversearcher-ag nfs-common net-tools lm-sensors network-manager-openvpn openvpn network-manager-openvpn-gnome curl nnn jq ubuntu-restricted-extras software-properties-common python3-dev python3-pip python3-distutils neovim gnome-tweak-tool

echo "[-] Installing ubuntu arc theme"
sudo apt-get install arc-theme arc-icons

echo "[-] Switch zsh as default shell"
chsh -s $(which zsh)

echo "[-] Installing gnome"
# Install gnome and switch to it
sudo apt-get install gnome-session gdm3
# Select the manual one, then logout of the session
sudo update-alternatives --config gdm3.css

echo "[-] Instaling oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

