#!/usr/bin/env bash

set -eu

read -p "Install arch packages? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  # update keyring
  yay -Sy archlinux-keyring

  # update packages
  yay -Syyu

  echo "[-] Installing colordiff to produce output with pretty syntax highlighting"
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
  echo "[-] Installing nss-myhostname: https://man7.org/linux/man-pages/man8/nss-myhostname.8.html"
  yay -S --noconfirm nss-myhostname

  echo "[-] Installing jo: https://github.com/jpmens/jo"
  yay -S --noconfirm jo

  echo "[-] Installing pgcli: https://github.com/dbcli/pgcli"
  yay -S --noconfirm pgcli

  #echo "[-] Installing podman: https://github.com/containers/podman"
  #yay -S --noconfirm podman

  echo "[-] Installing ripgrep: https://github.com/BurntSushi/ripgrep"
  yay -S --noconfirm ripgrep

  echo "[-] Installing obsidian: https://obsidian.md/"
  yay -S --noconfirm obsidian

  echo "[-] Installing httpie: https://httpie.io/"
  yay -S --noconfirm httpie

  echo "[-] installing aws-cli"
  yay -S --noconfirm aws-cli

  echo "[-] installing redshift: http://jonls.dk/redshift/"
  yay -S --noconfirm redshift

  #echo "[-] installing bitwarden-cli"
  #yay -S --noconfirm bitwarden-cli

  echo "[-] installing pass"
  yay -S --noconfirm pass

  echo "[-] installing stow"
  yay -S --noconfirm stow

  echo "[-] installing spotify"
  yay -S --noconfirm spotify

  echo "[-] installing gimp"
  yay -S --noconfirm gimp

  echo "[-] installing libreoffice"
  yay -S --noconfirm libreoffice-still

  echo "[-] installing playerctl to control players"
  yay -S --noconfirm playerctl

  echo "[-] installing peek: simple screen recorder with an easy to use interface"
  yay -S --noconfirm peek

  echo "[-] installing fd (> find): https://github.com/sharkdp/fd/"
  yay -S --noconfirm fd

  echo "[-] installing kafkactl"
  yay -S --noconfirm kafkactl

  echo "[-] installing lsd: https://github.com/Peltoche/lsd"
  yay -S --noconfirm lsd

  echo "[-] installing neovim"
  yay -S --noconfirm neovim

  echo "[-] installing delve (debugger for go): https://github.com/go-delve/delve"
  yay -S --noconfirm delve

  echo "[-] installing duf: https://github.com/muesli/duf"
  yay -S --noconfirm duf

  echo "[-] Finished installing stuffs"
fi

