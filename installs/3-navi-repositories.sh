#!/usr/bin/env bash

set -eu

install_navi_repository() {
  local vcs_source=$1
  local user=$2
  local repo=$3

  local target_folder
  target_folder="$(navi info cheats-path)/${user}__${repo}"

  if [ -d "${target_folder}" ]; then
    echo "[-] ${target_folder} already exists"
  else
    git clone "${vcs_source}:${user}/${repo}" "${target_folder}"
  fi
}

install_navi_repository "git@github.com" l-lin cheats
install_navi_repository "git@git.bioserenity.com" louis.lin cheats

