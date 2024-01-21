#!/usr/bin/env bash

set -eu

green='\e[0;32m'
escape='\e[0m'

info() {
  echo -e "$(date -u "+%H:%M:%SZ") ${green}INF ${escape}${1}"
}

read -p "Install arch packages? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  info "updating keyring"
  yay -Sy archlinux-keyring

  info "updating packages"
  yay -Syyu

  info "installing colordiff to produce output with pretty syntax highlighting"
  yay -S --noconfirm colordiff

  # xcb lib to compile jless
  # see https://github.com/PaulJuliusMartinez/jless/issues/87
  #yay -S librust-xcb+debug-all-dev

  # packages for pythons
  # zlib: deals with "No module named 'zlib'
  # libffi: deals with "No module named '_ctypes'
  # libbz2: deals with "No module named '_bz2'
  #yay -S python-setuptools \
  #  zlib1g-dev \
  #  libffi-dev \
  #  libbz2-dev

  # to resolve *.localhost automatically to 127.0.0.1
  info "installing nss-myhostname: https://man7.org/linux/man-pages/man8/nss-myhostname.8.html"
  yay -S --noconfirm nss-myhostname

  info "installing jo: https://github.com/jpmens/jo"
  yay -S --noconfirm jo

  info "installing pgcli: https://github.com/dbcli/pgcli"
  yay -S --noconfirm pgcli

  #info "Installing podman: https://github.com/containers/podman"
  #yay -S --noconfirm podman

  info "installing ripgrep: https://github.com/BurntSushi/ripgrep"
  yay -S --noconfirm ripgrep

  info "installing obsidian: https://obsidian.md/"
  yay -S --noconfirm obsidian

  info "installing httpie: https://httpie.io/"
  yay -S --noconfirm httpie

  info "installing redshift: http://jonls.dk/redshift/"
  yay -S --noconfirm redshift

  #info "installing bitwarden-cli"
  #yay -S --noconfirm bitwarden-cli

  info "installing pass"
  yay -S --noconfirm pass

  info "installing stow"
  yay -S --noconfirm stow

  info "installing gimp"
  yay -S --noconfirm gimp

  info "installing libreoffice"
  yay -S --noconfirm libreoffice-still

  info "installing playerctl to control players"
  yay -S --noconfirm playerctl

  info "installing peek: simple screen recorder with an easy to use interface"
  yay -S --noconfirm peek

  info "installing fd (> find): https://github.com/sharkdp/fd/"
  yay -S --noconfirm fd

  info "installing kafkactl"
  yay -S --noconfirm kafkactl

  info "installing lsd: https://github.com/Peltoche/lsd"
  yay -S --noconfirm lsd

  info "installing neovim"
  yay -S --noconfirm neovim

  info "installing delve (debugger for go): https://github.com/go-delve/delve"
  yay -S --noconfirm delve

  info "installing duf: https://github.com/muesli/duf"
  yay -S --noconfirm duf

  info "installing bashmount: https://github.com/jamielinux/bashmount"
  yay -S --noconfirm bashmount

  info "installing miller: https://github.com/johnkerl/miller"
  yay -S --noconfirm miller

  info "installing xsel"
  yay -S --noconfirm xsel

  info "installing sdcv (word definition)"
  yay -S --noconfirm sdcv

  info "installing w3m (terminal web browser)"
  yay -S --noconfirm w3m

  info "installing ddgr (DuckDuckGo from the terminal): https://github.com/jarun/ddgr"
  yay -S --noconfirm ddgr

  info "installing spotube: https://github.com/KRTirtho/spotube"
  yay -S --noconfirm spotube-bin

  info "finished installing stuffs"
fi

