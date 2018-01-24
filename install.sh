#!/bin/bash

set -e
set -x

DC_VERSION="1.18.0"

echo "[-] Installing stuffs..."
sudo pip install --upgrade pip 
sudo pip install --upgrade virtualenv 
echo "[-] Installing power-line for VIM airline"
sudo apt-get install python-setuptools
sudo pip install powerline-status
echo "[-] Instaling TMUX plugin manager"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
echo "[-]  Installing zsh plugins"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
git clone https://github.com/paulirish/git-open.git ${ZSH_CUSTOM}/plugins/git-open
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
git clone https://github.com/lukechilds/zsh-nvm ${ZSH_CUSTOM}/plugins/zsh-nvm
git clone https://github.com/denysdovhan/spaceship-prompt.git ${ZSH_CUSTOM}/themes/spaceship-prompt
ln -s ${ZSH_CUSTOM}/themes/spaceship-prompt/spaceship.zsh-theme ${ZSH_CUSTOM}/themes/spaceship.zsh-theme
echo "[-] Installing Git Run: https://github.com/mixu/gr"
npm i -g git-run
echo "[-] Installing Yarn"
npm i -g yarn
echo "[-] Installing colorls: https://github.com/athityakumar/colorls"
git clone https://github.com/ryanoasis/nerd-fonts --depth 1 /tmp/nerd-fonts
cd /tmp/nerd-fonts && ./install.sh
sudo gem install colorls
echo "[-] Installing Docker"
curl -fsSL https://get.docker.com/ | sh
docker --version
echo "[-] Installing Docker Compose"
curl -L https://github.com/docker/compose/releases/download/${DC_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose -version
echo "[-] Add Docker compose bash completion"
sudo curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

echo "[-] Installation SUCCESS! Please restart your terminal"
exit 0

