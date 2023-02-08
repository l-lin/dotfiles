#!/usr/bin/env bash

set -eu

themes_path="${HOME}/.themes"
theme_name="gruvbox-material-dark-blocks"

mkdir -p "${themes_path}"

if [[ ! -d "${themes_path}/tmp" ]]; then
  echo "[-] Installing ${theme_name} theme"
  git clone https://github.com/nathanielevan/gruvbox-material-openbox "${themes_path}/tmp"
  mv "${themes_path}/tmp/${theme_name}" "${themes_path}/${theme_name}"

  rm -rf "${themes_path}/tmp"
else
  echo "[-] Theme ${theme_name} already installed"
fi


