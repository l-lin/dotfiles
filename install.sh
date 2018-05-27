#!/bin/bash

set -e
set -x

DC_VERSION="1.18.0"
GO_VERSION="1.10.1"

echo "[-] Creating folders..."
mkdir -p $HOME/apps
mkdir -p $HOME/bin
echo "[-] Installing stuffs..."
sudo pip install --upgrade pip 
sudo pip install --upgrade virtualenv 
echo "[-] Installing power-line for VIM airline"
sudo apt-get install python-setuptools
sudo pip install powerline-status
echo "[-] Instaling TMUX plugin manager"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
echo "[-] Instaling oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
echo "[-]  Installing zsh plugins"
/usr/bin/zsh
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
echo "[-] Installing fuzzy finder"
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
echo "[-] Installing pet: https://github.com/knqyf263/pet#debian-ubuntu"
wget -O /tmp/pet.deb https://github.com/knqyf263/pet/releases/download/v0.3.0/pet_0.3.0_linux_amd64.deb
sudo dpkg -i /tmp/pet.deb
echo "[-] Installing ctop"
sudo wget https://github.com/bcicen/ctop/releases/download/v0.7.1/ctop-0.7.1-linux-amd64 -O /usr/local/bin/ctop
sudo chmod +x /usr/local/bin/ctop
echo "[-] Installing Golang"
GO_FILE=go${GO_VERSION}.linux-amd64
curl -o /tmp/${GO_FILE}.tar.gz https://dl.google.com/go/${GO_FILE}.tar.gz
tar xzvf /tmp/${GO_FILE}.tar.gz -C $HOME
echo "[-] Installing pet"
go get -u github.com/knqyf263/pet

echo "[-] Installation SUCCESS! Please restart your terminal"
exit 0

