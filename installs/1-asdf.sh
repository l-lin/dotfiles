#!/usr/bin/env bash

set -eu

asdf_version="0.10.2"
asdf_home="$HOME/.asdf"

install_plugin() {
  local name=
  local cmd=
  local version=latest
  local src=
  TEMP=$(getopt -o '' --long 'name:,cmd:,version:,source:' -n "${0##*/}" -- "$@")
  eval set -- "$TEMP"
  unset TEMP
  while true; do
    case "${1}" in
      '--name')
        name="${2}"
        shift 2
        continue
        ;;
      '--cmd')
        cmd="${2}"
        shift 2
        continue
        ;;
      '--version')
        version="${2}"
        shift 2
        continue
        ;;
      '--source')
        src="${2}"
        shift 2
        continue
        ;;
      '--')
        shift
        break
        ;;
      *)
        break
        ;;
    esac

    shift
  done

  check_variable 'name' "${name}"
  check_variable 'version' "${version}"

  # set name to cmd if not set
  cmd=${cmd:-${name}}

  if type "${cmd}" >/dev/null 2>&1; then
    echo "[-] ${name} already installed => skipping"
  else
    asdf plugin add "${name}" "${cmd}" | true

    local version_to_install
    if [ 'latest' == "${version}" ]; then
      version_to_install=$(asdf list all "${name}" | sort -V -r | head -n 1)
    else
      version_to_install="${version}"
    fi

    echo "[-] installing ${name} ${version_to_install}"
    asdf install "${name}" "${version_to_install}"
    asdf global "${name}" "${version_to_install}"
  fi
}

check_variable() {
  local variable_name="${1}"
  local variable="${2}"
  if [[ -z "${variable}" ]]; then
    >&2 echo "[x] Missing flags '--${variable_name}'"
    exit 1
  fi
}

install_asdf() {
  if [ ! -d "${asdf_home}" ]; then
    echo "[-] installing asdf"
    git clone https://github.com/asdf-vm/asdf.git "${HOME}/.asdf" --branch "v${asdf_version}"
  else
    echo "[-] asdf already installed => skipping"
  fi
}

install_asdf

# https://github.com/sharkdp/bat
install_plugin --name bat
if [ ! -e "${HOME}/.asdf/shims/bat" ]; then
  sudo ln -s "${HOME}/.asdf/shims/bat" /usr/local/bin/bat
fi
install_plugin --name checkov
install_plugin --name golang --cmd go
install_plugin --name gohugo --cmd hugo --version 'extended_0.80.0'
install_plugin --name gradle
install_plugin --name groovy
install_plugin --name helm
install_plugin --name imagemagick --cmd convert --source 'https://github.com/mangalakader/asdf-imagemagick'
install_plugin --name java --version 'adoptopenjdk-17.0.0+35'
install_plugin --name k3d
install_plugin --name kubectl
install_plugin --name maven --cmd mvn
install_plugin --name mongosh
install_plugin --name mvnd --source 'https://github.com/joschi/asdf-mvnd'
install_plugin --name nodejs --cmd node
install_plugin --name quarkus --source 'https://github.com/HonoluluHenk/asdf-quarkus.git'
install_plugin --name rust --cmd cargo --source 'https://github.com/code-lever/asdf-rust.git'
# https://www.shellcheck.net/
install_plugin --name shellcheck
install_plugin --name sops
install_plugin --name terraform
install_plugin --name starship

