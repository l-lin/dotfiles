#!/usr/bin/env zsh

set -eu

install_zsh_plugin() {
  local git_url=$1
  local plugin_name=$2
  local plugin_folder="${ZSH_CUSTOM}/plugins/${plugin_name}"
  if [ ! -d "${plugin_folder}" ]; then
    echo "[-] installing zsh plugin ${plugin_name}"
    git clone "${git_url}" "${plugin_folder}"
  else
    echo "[-] zsh plugin ${plugin_name} already exists => skipping"
  fi
}

install_zsh_plugin https://github.com/zsh-users/zsh-syntax-highlighting.git zsh-syntax-highlighting
install_zsh_plugin https://github.com/paulirish/git-open.git git-open
install_zsh_plugin https://github.com/zsh-users/zsh-autosuggestions.git zsh-autosuggestions
install_zsh_plugin https://github.com/lukechilds/zsh-nvm zsh-nvm
install_zsh_plugin https://github.com/wfxr/forgit forgit
install_zsh_plugin https://github.com/ianthehenry/zsh-autoquoter zsh-autoquoter
install_zsh_plugin https://github.com/unixorn/git-extra-commands git-extra-commands


if [ ! -d "${ZSH_CUSTOM}/themes/spaceship-prompt" ]; then
  echo "[-] installing spaceship-prompt theme"
  git clone https://github.com/denysdovhan/spaceship-prompt.git ${ZSH_CUSTOM}/themes/spaceship-prompt
  ln -s ${ZSH_CUSTOM}/themes/spaceship-prompt/spaceship.zsh-theme ${ZSH_CUSTOM}/themes/spaceship.zsh-theme
else
  echo "[-] spaceship-prompt theme already installed => skipping"
fi

