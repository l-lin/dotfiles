#!/bin/bash

set -euo
set -x

docker_compose_version="1.25.5"
go_version="1.15"
nvm_version="0.35.3"
pet_version="0.3.6"
ctop_version="0.7.3"
bat_version="0.15.0"
fd_version="8.0.0"
java_id="11.0.7.hs-adpt"
lsd_version="0.17.0"
python_version="3.5.4"
dip_version="6.1.0"

echo "[-] Creating folders..."
mkdir -p $HOME/apps
mkdir -p $HOME/bin
mkdir -p $HOME/work
mkdir -p $HOME/perso
mkdir -p $HOME/.zsh/completion
mkdir -p $HOME/go
mkdir -p $HOME/.undodir

echo "[-] Installing pyenv..."
git clone https://github.com/pyenv/pyenv.git $HOME/apps/pyenv
pyenv install $python_version
pyenv global $python_version
pyenv rehash

echo "[-] Installing pyenv-virtualenv plugin"
git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv

echo "[-] Installing power-line for VIM airline"
sudo apt-get install python-setuptools
sudo pip3 install powerline-status

echo "[-] Installing TMUX plugin manager"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo "[-] Installing pgcli"
sudo apt install libpq-dev
sudo pip3 install --upgrade pgcli

echo "[-] Installing Neovim"
sudo snap install --beta nvim --classic

echo "[-] Installing NVM"
mkdir -p $HOME/.nvm
curl -o- https://raw.githubusercontent.com/creationix/nvm/v${nvm_version}/install.sh | bash

echo "[-] Installing LSD: https://github.com/Peltoche/lsd"
curl -L -o /tmp/lsd.deb https://github.com/Peltoche/lsd/releases/download/${lsd_version}/lsd_${lsd_version}_amd64.deb
sudo dpkg -i /tmp/lsd.deb

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

echo "[-] Installing Golang Version Manager & Golang ${go_version}"
bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
source "${HOME}/.gvm/scripts/gvm"
gvm install "${go_version}"
gvm use "${go_version}" --default

echo "[-] Installing cht.sh: https://github.com/chubin/cheat.sh"
sudo curl -o /usr/local/bin/cht.sh https://cht.sh/:cht.sh
sudo chmod +x /usr/local/bin/cht.sh
curl https://cheat.sh/:zsh > $HOME/.zsh/completion/_cht

echo "[-] Installing dip: https://github.com/bibendi/dip"
sudo curl -o /usr/local/bin/dip -L https://github.com/bibendi/dip/releases/download/v${dip_version}/dip-$(uname -s)-$(uname -m)
sudo chmod +x /usr/local/bin/dip

echo "[-] Installing fac: https://github.com/mkchoi212/fac"
go get github.com/mkchoi212/fac

echo "[-] Installing vscode"
sudo snap install code --classic

echo "[-] Installing gohugo"
sudo snap install hugo --channel=extended

echo "[-] Installing node"
nvm install 12

echo "[-] Installing node client for neovim"
npm i -g neovim

echo "[-] Installing python3 extension for nvim"
python3 -m pip install --user --upgrade pynvim

echo "[-] Installing SDKMan"
curl -s "https://get.sdkman.io" | bash
sdk install maven
sdk install java "${java_id}"

echo "[-] Set default editor to NVIM"
sudo update-alternatives --install /usr/bin/editor editor /snap/nvim/current/usr/bin/nvim 100

echo "[-] Installation SUCCESS!"
exit 0
