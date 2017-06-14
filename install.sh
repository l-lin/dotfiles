#!/bin/bash

set -e

echo "[-] Installing stuffs..."
sudo pip install --upgrade pip 
sudo pip install --upgrade virtualenv 
echo "[-] Installing power-line for VIM airline"
sudo pip install powerline-status
echo "[-] Instaling TMUX plugin manager"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
echo "[-]  Installing zsh plugins"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/paulirish/git-open.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/git-open
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/lukechilds/zsh-nvm ~/.oh-my-zsh/custom/plugins/zsh-nvm
echo "[-] Installing Git Run: https://github.com/mixu/gr"
npm install -g git-run
echo "[-] Installing Docker"
curl -fsSL https://get.docker.com/ | sh
docker --version
echo "[-] Installing Docker Compose"
curl -L https://github.com/docker/compose/releases/download/1.13.0/docker-compose-`uname -s`-`uname -m` > /tmp/docker-compose
chmod +x /tmp/docker-compose && sudo mv /tmp/docker-compose /usr/local/bin/
docker-compose -version
echo "[-] Add Docker compose bash completion"
sudo curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

echo "[-] Installation SUCCESS!"
exit 0

