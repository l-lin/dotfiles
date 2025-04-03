#!/usr/bin/env bash
#
# Import SSH keys, sops key and init git on newly fresh NixOS installation.
#

set -euo pipefail

BW_SESSION=""

ssh_dir="${HOME}/.ssh"
sops_dir="${HOME}/.config/sops"

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
  local ssh_key_filename=${2}
  local public_key="${ssh_dir}/${ssh_key_filename}.pub"
  local private_key="${ssh_dir}/${ssh_key_filename}"

  info "Creating dir ${ssh_dir}/..."
  mkdir -p "${ssh_dir}"
  chmod 700 "${ssh_dir}"

  info "Importing public key ${public_key}..."
  get_bw_notes "ssh.pub@${username}" "${public_key}"
  chmod 644 "${public_key}"

  info "Importing private key ${private_key}..."
  get_bw_notes "ssh@${username}" "${private_key}"
  chmod 600 "${private_key}"
}

create_git_allowed_signers() {
  local username=${1}
  local ssh_key_filename=${2}
  local email=${3}
  local public_key="${ssh_dir}/${ssh_key_filename}.pub"

  info "Adding ${username} to ${ssh_dir}/allowed_signers..."
  echo "${email} namespaces=\"git\" $(cat "${public_key}")" >> "${ssh_dir}/allowed_signers"
}

import_sops_age_key() {
  local username=${1}
  local ssh_key_filename=${2}
  local age_key="${sops_dir}/age/keys.txt"
  local private_key="${ssh_dir}/${ssh_key_filename}"

  info "Creating dir ${sops_dir}/age/..."
  mkdir -p "${sops_dir}/age"
  chmod 700 "${sops_dir}/age"

  info "Importing SOPS age key ${age_key}..."
  SSH_TO_AGE_PASSPHRASE="$(get_bw_value "ssh@${username}" 'passphrase')" \
    ssh-to-age -private-key -i "${private_key}" >> "${age_key}"
  chmod 600 "${age_key}"
}

unlock_bw() {
  BW_SESSION="$(bw login --raw || bw unlock --raw)"
  export BW_SESSION
}

unlock_bw
bw sync

# Import personal SSH key.

email="lin.louis@pm.me"
username="l-lin"
ssh_key_filename="${username}"
import_ssh_keys "${username}" "${ssh_key_filename}"
create_git_allowed_signers "${username}" "${ssh_key_filename}" "${email}"
import_sops_age_key "${username}" "${ssh_key_filename}"

# Import work SSH key.
email="louis.lin@doctolib.com"
username="doctolib"
ssh_key_filename="id_ed25519_$(hostname | sed 's/-/_/')"
import_ssh_keys "${username}" "${ssh_key_filename}"
create_git_allowed_signers "${username}" "${ssh_key_filename}" "${email}"
import_sops_age_key "${username}" "${ssh_key_filename}"

bw lock

info "Keys imported successfully!!!"
