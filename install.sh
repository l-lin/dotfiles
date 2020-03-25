#!/bin/bash

set -e
set -x

docker_compose_version="1.18.0"
go_version="1.14.1"
nvm_version="0.33.11"
pet_version="0.3.6"
ctop_version="0.7.1"
bat_version="0.12.1"
fd_version="7.1.0"

echo "[-] Creating folders..."
mkdir -p $HOME/apps
mkdir -p $HOME/bin
mkdir -p $HOME/work
mkdir -p $HOME/perso
mkdir -p $HOME/.zsh/completion
mkdir -p $HOME/go
mkdir -p $HOME/.undodir
echo "[-] Installing stuffs..."
sudo pip install --upgrade pip 
sudo pip install --upgrade virtualenv 
echo "[-] Installing power-line for VIM airline"
sudo apt-get install python-setuptools
sudo pip install powerline-status
echo "[-] Installing TMUX plugin manager"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
echo "[-] Installing pgcli"
sudo pip install --upgrade pgcli

echo "[-] Installing NVM"
mkdir -p $HOME/.nvm
curl -o- https://raw.githubusercontent.com/creationix/nvm/v${nvm_version}/install.sh | bash

echo "[-] Installing LSD: https://github.com/Peltoche/lsd"
snap install lsd --classic

echo "[-] Installing Docker"
curl -fsSL https://get.docker.com/ | sh
docker --version
sudo usermod -aG docker $USER

echo "[-] Installing Docker Compose: https://github.com/docker/compose"
sudo curl -o /usr/local/bin/docker-compose -L https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-`uname -s`-`uname -m`
sudo chmod +x /usr/local/bin/docker-compose
docker-compose -version

echo "[-] Installing fuzzy finder"
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

echo "[-] Installing pet: https://github.com/knqyf263/pet#debian-ubuntu"
curl -L -o /tmp/pet.deb https://github.com/knqyf263/pet/releases/download/v${pet_version}/pet_${pet_version}_linux_amd64.deb
sudo dpkg -i /tmp/pet.deb

echo "[-] Installing bat: https://github.com/sharkdp/bat"
curl -L -o /tmp/bat.deb https://github.com/sharkdp/bat/releases/download/v${bat_version}/bat_${bat_version}_amd64.deb
sudo dpkg -i /tmp/bat.deb

echo "[-] Installing prettyping: https://github.com/denilsonsa/prettyping"
sudo curl -L -o /usr/local/bin/prettyping https://raw.githubusercontent.com/denilsonsa/prettyping/master/prettyping
sudo chmod +x /usr/local/bin/prettyping

echo "[-] Installing ctop"
sudo curl -L -o /usr/local/bin/ctop https://github.com/bcicen/ctop/releases/download/v${ctop_version}/ctop-${ctop_version}-linux-amd64
sudo chmod +x /usr/local/bin/ctop

echo "[-] Installing diff-so-fancy: https://github.com/so-fancy/diff-so-fancy"
sudo curl -L -o /usr/local/bin/diff-so-fancy https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy
sudo chmod +x /usr/local/bin/diff-so-fancy

echo "[-] Installing fd (> find): https://github.com/sharkdp/fd/"
curl -o /tmp/fd.deb -L https://github.com/sharkdp/fd/releases/download/v${fd_version}/fd_${fd_version}_amd64.deb
sudo dpkg -i /tmp/fd.deb

echo "[-] Installing Golang"
go_file_name=go${go_version}.linux-amd64
curl -o /tmp/${go_file_name}.tar.gz https://dl.google.com/go/${go_file_name}.tar.gz
tar xzvf /tmp/${go_file_name}.tar.gz -C $HOME/apps
export GOROOT="$HOME/apps/go"
export GOPATH="$HOME/go"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

echo "[-] Installing pet"
go get -u github.com/knqyf263/pet

echo "[-] Installing cht.sh: https://github.com/chubin/cheat.sh"
sudo curl -o /usr/local/bin/cht.sh https://cht.sh/:cht.sh
sudo chmod +x /usr/local/bin/cht.sh
curl https://cheat.sh/:zsh > $HOME/.zsh/completion/_cht

echo "[-] Installing fac: https://github.com/mkchoi212/fac"
go get github.com/mkchoi212/fac

echo "[-] Installing vscode"
sudo snap install code --classic

echo "[-] Installing gohugo"
sudo snap install hugo

echo "[-] Installing IntelliJ CE"
sudo snap install intellij-idea-community --classic 

echo "[-] Installation SUCCESS!"
exit 0
