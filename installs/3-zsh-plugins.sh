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
install_zsh_plugin https://github.com/romkatv/gitstatus gitstatus
install_zsh_plugin https://github.com/jeffreytse/zsh-vi-mode zsh-vi-mode
install_zsh_plugin https://github.com/Aloxaf/fzf-tab fzf-tab
install_zsh_plugin https://github.com/Freed-Wu/fzf-tab-source fzf-tab-source
