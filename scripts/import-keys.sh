#!/usr/bin/env bash
#
# Import SSH keys, sops key and init git on newly fresh NixOS installation.
#

set -euo pipefail

BW_SESSION=""

declare -A keys=([l-lin]=lin.louis@pm.me [doctolib]=louis.lin@doctolib.com)

ssh_folder="${HOME}/.ssh"
sops_folder="${HOME}/.config/sops"

# colors for logging
blue="\e[1;30;44m"
nc="\e[0m"

info() {
  echo -e "${blue} I ${nc} ${1}"
}

get_bw_notes() {
  local name=$1
  local destination=$2
  local notes

  notes="$(bw list items --search "$name" | jq -r '.[].notes')"
  printf "%b\n" "$notes" > "$destination"
}

get_bw_value() {
  local name=$1
  local field_name=$2
  bw list items --search "$name" | jq -r '.[].fields[] | select(.name = "'"$field_name"'") | .value'
}

import_ssh_keys() {
  local username=${1}
  local public_key="${ssh_folder}/${username}.pub"
  local private_key="${ssh_folder}/${username}"

  info "Creating folder ${ssh_folder}/..."
  mkdir -p "${ssh_folder}"
  chmod 700 "${ssh_folder}"

  info "Importing public key ${public_key}..."
  get_bw_notes "ssh.pub@${username}" "${public_key}"
  chmod 644 "${public_key}"

  info "Importing private key ${private_key}..."
  get_bw_notes "ssh@${username}" "${private_key}"
  chmod 600 "${private_key}"
}

create_git_allowed_signers() {
  local username=${1}
  local email=${2}
  local public_key="${ssh_folder}/${username}.pub"

  info "Adding ${username} to ${ssh_folder}/allowed_signers..."
  echo "${email} namespaces=\"git\" $(cat "${public_key}")" >> "${ssh_folder}/allowed_signers"
}

import_sops_age_key() {
  local username=${1}
  local age_key="${sops_folder}/age/${username}.age"

  info "Creating folder ${sops_folder}/age/..."
  mkdir -p "${sops_folder}/age"
  chmod 700 "${sops_folder}/age"

  info "Importing SOPS age key ${age_key}..."
  SSH_TO_AGE_PASSPHRASE="$(get_bw_value "ssh@${username}" 'passphrase')" \
    ssh-to-age -private-key -i "${ssh_folder}/${username}" > "${age_key}"
  chmod 600 "${age_key}"
}

unlock_bw() {
  BW_SESSION="$(bw login --raw || bw unlock --raw)"
  export BW_SESSION
}

unlock_bw

for username in "${!keys[@]}"; do
  email="${keys[${username}]}"
  import_ssh_keys "${username}"
  create_git_allowed_signers "${username}" "${email}"
  import_sops_age_key "${username}"
done

bw lock

info "Keys imported successfully!!!"
