#!/usr/bin/env bash

set -eu

install_theme() {
	local theme_path="${1}"
	local theme_name="${2}"
	local git_project="${3}"
  local git_project_name="${4}"

	if [[ ! -d "${theme_path}/${theme_name}" ]]; then
		mkdir -p "${theme_path}"

		echo "[-] Installing ${theme_name} theme"
		git clone "${git_project}" "/tmp/${git_project_name}"
		mv "/tmp/${git_project_name}/${theme_name}" "${theme_path}/${theme_name}"

		rm -rf "/tmp/${git_project_name}"
	else
		echo "[-] Theme ${theme_name} already installed"
	fi
}

install_theme \
  "${HOME}/.themes" \
	"gruvbox-material-dark-blocks" \
	"https://github.com/nathanielevan/gruvbox-material-openbox" \
  "gruvbox-material-openbox"

install_theme \
  "$(bat --config-dir)/themes" \
  "Catppuccin-mocha.tmTheme" \
  "https://github.com/catppuccin/bat" \
  "catppuccin"
