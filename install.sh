#!/bin/bash

set -e
set -x

docker_compose_version="1.18.0"
go_version="1.10.1"
nvm_version="0.33.11"
pet_version="0.3.0"
ctop_version="0.7.1"
bat_version="0.6.0"
fd_version="7.1.0"

echo "[-] Creating folders..."
mkdir -p $HOME/apps
mkdir -p $HOME/bin
mkdir -p $HOME/work
mkdir -p $HOME/perso
mkdir -p $HOME/.zsh/completion
mkdir -p $HOME/go
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

echo "[-] Installing Docker Compose: https://github.com/docker/compose"
curl -o /usr/local/bin/docker-compose -L https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-`uname -s`-`uname -m`
sudo chmod +x /usr/local/bin/docker-compose
docker-compose -version

echo "[-] Add Docker compose completion"
curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/zsh/_docker-compose > ~/.zsh/completion/_docker-compose

echo "[-] Installing fuzzy finder"
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

echo "[-] Installing pet: https://github.com/knqyf263/pet#debian-ubuntu"
curl -o /tmp/pet.deb https://github.com/knqyf263/pet/releases/download/v${pet_version}/pet_${pet_version}_linux_amd64.deb
sudo dpkg -i /tmp/pet.deb

echo "[-] Installing bat: https://github.com/sharkdp/bat"
curl -o /tmp/bat.deb https://github.com/sharkdp/bat/releases/download/v${bat_version}/bat_${bat_version}_amd64.deb
sudo dpkg -i /tmp/bat.deb

echo "[-] Installing prettyping: https://github.com/denilsonsa/prettyping"
sudo curl -o /usr/local/bin/prettyping https://raw.githubusercontent.com/denilsonsa/prettyping/master/prettyping
chmod +x /usr/local/bin/prettyping

echo "[-] Installing ctop"
sudo curl -o /usr/local/bin/ctop https://github.com/bcicen/ctop/releases/download/v${ctop_version}/ctop-${ctop_version}-linux-amd64
sudo chmod +x /usr/local/bin/ctop

echo "[-] Installing diff-so-fancy: https://github.com/so-fancy/diff-so-fancy"
sudo curl -o /usr/local/bin/diff-so-fancy https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy
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

echo "[-] Installing blush"
go get github.com/arsham/blush

echo "[-] Installing cht.sh: https://github.com/chubin/cheat.sh"
sudo curl -o /usr/local/bin/cht.sh https://cht.sh/:cht.sh
sudo chmod +x /usr/local/bin/cht.sh

echo "[-] Installing fac: https://github.com/mkchoi212/fac"
go get github.com/mkchoi212/fac

echo "[-] Installation SUCCESS!"
exit 0
