#
# SSH related stuff.
#

{ pkgs, userSettings, ... }: let
  # We are at NixOS level, not home-manager, so no user specific variable available like `home.homeDirectory`.
  sshFolder = "/home/${userSettings.username}/.ssh";
  sopsFolder = "/home/${userSettings.username}/.config/sops";
in {
  services.openssh = {
    enable = true;
    settings = {
      AllowUsers = [ userSettings.username ];
      # Allow ssh using passphrase, for easier connection to VM.
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  # Start the OpenSSH agent when you log in.
  # The OpenSSH agent remembers private keys for you so that you don’t have to type in passphrases
  # every time you make an SSH connection.
  # Use ssh-add to add a key to the agent.
  programs.ssh.startAgent = true;

  environment.systemPackages = with pkgs; [
    # Shell script to import SSH keys, sops key and init git on newly fresh NixOS installation.
    (writeShellScriptBin "import-keys" ''
#!/usr/bin/env bash
#
# Import SSH keys, sops key and init git on newly fresh NixOS installation.
#

set -euo pipefail

BLUE="\e[1;30;44m"
NC="\e[0m"

BW_SESSION=""

info() {
  echo -e "$BLUE I $NC $1"
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
  local public_key
  local private_key
  public_key="${sshFolder}/${userSettings.username}.pub"
  private_key="${sshFolder}/${userSettings.username}"

  info "Creating folder ${sshFolder}/..."
  mkdir -p "${sshFolder}"
  chmod 700 "${sshFolder}"

  info "Importing public key $public_key..."
  get_bw_notes "ssh.pub@${userSettings.username}" "$public_key"
  chmod 644 "$public_key"

  info "Importing private key $private_key..."
  get_bw_notes "ssh@${userSettings.username}" "$private_key"
  chmod 600 "$private_key"
}

create_git_allowed_signers() {
  local public_key
  public_key="${sshFolder}/${userSettings.username}.pub"

  info "Creating file ${sshFolder}/allowed_signers..."
  echo "${userSettings.email} namespaces=\"git\" $(cat $public_key)" > "${sshFolder}/allowed_signers"
}

import_sops_age_key() {
  local age_key
  age_key="${sopsFolder}/age/${userSettings.username}.age"

  info "Creating folder ${sopsFolder}/age/..."
  mkdir -p "${sopsFolder}/age"
  chmod 700 "${sopsFolder}/age"

  info "Importing SOPS age key $age_key..."
  SSH_TO_AGE_PASSPHRASE="$(get_bw_value ssh@${userSettings.username} 'passphrase')" \
    ssh-to-age -private-key -i "${sshFolder}/${userSettings.username}" > "$age_key"
  chmod 600 "$age_key"
}

unlock_bw() {
  BW_SESSION="$(bw login --raw || bw unlock --raw)"
  export BW_SESSION
}

unlock_bw
import_ssh_keys
create_git_allowed_signers
import_sops_age_key

bw lock
    '')
  ];
}
