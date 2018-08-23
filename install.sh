#!/bin/bash

set -e
set -x

docker_compose_version="1.18.0"
go_version="1.10.1"
nvm_version="0.33.11"
pet_version="0.3.0"
ctop_version="0.7.1"

echo "[-] Creating folders..."
mkdir -p $HOME/apps
mkdir -p $HOME/bin
mkdir -p $HOME/work
mkdir -p $HOME/perso
mkdir -p $HOME/.zsh/completion
echo "[-] Installing stuffs..."
sudo pip install --upgrade pip 
sudo pip install --upgrade virtualenv 
echo "[-] Installing power-line for VIM airline"
sudo apt-get install python-setuptools
sudo pip install powerline-status
echo "[-] Instaling TMUX plugin manager"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo "[-] Installing NVM"
curl -o- https://raw.githubusercontent.com/creationix/nvm/v${nvm_version}/install.sh | bash

sudo gem install colorls

echo "[-] Installing Docker"
curl -fsSL https://get.docker.com/ | sh
docker --version

echo "[-] Installing Docker Compose"
curl -L https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-`uname -s`-`uname -m` > /tmp/docker-compose
sudo mv /tmp/docker-compose /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose -version

echo "[-] Add Docker compose completion"
curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/zsh/_docker-compose > ~/.zsh/completion/_docker-compose

echo "[-] Installing fuzzy finder"
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

echo "[-] Installing pet: https://github.com/knqyf263/pet#debian-ubuntu"
wget -O /tmp/pet.deb https://github.com/knqyf263/pet/releases/download/v${pet_version}/pet_${pet_version}_linux_amd64.deb
sudo dpkg -i /tmp/pet.deb

echo "[-] Installing ctop"
sudo wget https://github.com/bcicen/ctop/releases/download/v${ctop_version}/ctop-${ctop_version}-linux-amd64 -O /usr/local/bin/ctop
sudo chmod +x /usr/local/bin/ctop

echo "[-] Installing Golang"
go_file_name=go${go_version}.linux-amd64
curl -o /tmp/${go_file_name}.tar.gz https://dl.google.com/go/${go_file_name}.tar.gz
tar xzvf /tmp/${go_file_name}.tar.gz -C $HOME

echo "[-] Installing pet"
go get -u github.com/knqyf263/pet

echo "[-] Installation SUCCESS!"
exit 0
