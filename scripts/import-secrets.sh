#!/usr/bin/env bash
#
# Clone secrets repository to local.
#

set -euo pipefail

username=${1:-louis.lin}
ssh_config_file="${HOME}/.ssh/config"
ssh_config_exists=$([ -f "${ssh_config_file}" ] && echo true || echo false)
secrets_repo='git@github.com:l-lin/secrets.git'
secrets_target_folder="${HOME}/.config/dotfiles/secrets"

# colors for logging
blue="\e[1;30;44m"
red="\e[1;30;41m"
nc="\e[0m"

info() {
	echo -e "${blue} I ${nc} ${1}"
}

error() {
	echo -e "${red} E ${nc} ${1}"
}

check_dependencies() {
  if ! type git >/dev/null 2>&1; then
    error "GIT not installed, please install it first, e.g. 'nix-shell -p git'."
    exit 1
  fi
}

init_ssh_config() {
	if [ "${ssh_config_exists}" = false ]; then
		info "Creating temporary SSH config, so we can clone the 'secrets' repository."
		cat <<EOF > "${ssh_config_file}"
Host github.com
  IdentityFile ${HOME}/.ssh/${username}
EOF
	fi
}

clean_up() {
	if [ "${ssh_config_exists}" = false ]; then
		info "Removing temporary SSH config, this will be created by home-manager."
		rm "${ssh_config_file}"
	fi
}

import_secrets() {
  info "Importing secrets from ${secrets_repo} to ${secrets_target_folder}"
  git clone "${secrets_repo}" "${secrets_target_folder}"
}

check_dependencies
init_ssh_config
import_secrets
clean_up

