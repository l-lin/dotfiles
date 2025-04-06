#!/usr/bin/env bash
#
# Import SSH keys, sops key and init git on newly fresh NixOS installation.
#

set -euo pipefail

BW_SESSION=""

ssh_dir="${HOME}/.ssh"
sops_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/sops"

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

import_all() {
  local email=${1}
  local username=${2}
  local ssh_key_filename="${3}"

  import_ssh_keys "${username}" "${ssh_key_filename}"
  create_git_allowed_signers "${username}" "${ssh_key_filename}" "${email}"
  import_sops_age_key "${username}" "${ssh_key_filename}"
}

# When decrypting a file with the corresponding identity, SOPS will look for a text file name keys.txt
# located in a sops subdirectory of your user configuration directory.
# On Linux, this would be $XDG_CONFIG_HOME/sops/age/keys.
# If $XDG_CONFIG_HOME is not set $HOME/.config/sops/age/keys.txt is used instead.
# On macOS, this would be $HOME/Library/Application Support/sops/age/keys.
#
# For some reason I don't understand, sometimes, it's looking at the official path
# $HOME/Library/Application Support/sops/age/keys.txt, and some other times
# it's looking at $XDG_CONFIG_HOME/sops/age/keys.txt...
# So creating the keys in both location will cover all use cases.
#
# src: https://github.com/getsops/sops?tab=readme-ov-file#encrypting-using-age
import_sops_age_key_for_darwin() {
  if [[ "${OSTYPE}" == "darwin"* ]]; then
    local age_key="${sops_dir}/age/keys.txt"
    local darwin_sops_dir="${HOME}/Library/Application Support/sops"
    local darwin_age_key="${darwin_sops_dir}/age/keys.txt"

    info "Creating dir ${darwin_sops_dir}/age/..."
    mkdir -p "${darwin_sops_dir}/age"
    chmod 700 "${darwin_sops_dir}/age"

    info "Creating symlink SOPS age key for macOS from ${age_key} to ${darwin_age_key}..."
    ln -s "${age_key}" "${darwin_age_key}"
  fi
}

unlock_bw
bw sync

# Import personal SSH key.
email="lin.louis@pm.me"
username="louis.lin"
ssh_key_filename="${username}"
import_all "${email}" "${username}" "${ssh_key_filename}"

# Import SSH key for work related secrets.
email="louis.lin@doctolib.com"
username="doctolib"
ssh_key_filename="${username}"
import_all "${email}" "${username}" "${ssh_key_filename}"

# Import work SSH key dedicated to the machine.
email="louis.lin@doctolib.com"
username="doctolib/macos"
ssh_key_filename="id_ed25519_$(hostname | sed 's/-/_/')"
import_all "${email}" "${username}" "${ssh_key_filename}"

import_sops_age_key_for_darwin

bw lock

info "Keys imported successfully!!!"
