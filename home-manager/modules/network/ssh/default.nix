#
# SSH
#

{ pkgs, userSettings, ... }: {
  # programs = {
  #   ssh = {
  #     enable = true;
  #     # When enabled, a private key that is used during authentication will be
  #     # added to ssh-agent if it is running (with confirmation enabled if
  #     # set to 'confirm'. The argument must be 'no' (the default), 'yes', 'confirm'
  #     # (optionally followed by a time interval), 'ask' or a time interval (e.g. '1h').
  #     addKeysToAgent = "yes";
  #     matchBlocks = {
  #       "*" = {
  #         identityFile = "${config.home.homeDirectory}/.ssh/${userSettings.username}";
  #       };
  #       "swp*" = {
  #         user = "admin";
  #       };
  #       "preprod-*" = {
  #         user = "admin";
  #       };
  #     };
  #   };
  # };

  home.packages = with pkgs; [
    # We need to declare as a global function instead of creating a zsh function because
    # it's a special script that reads the stdin, and the zsh plugin that provides functions
    # is a wrapper around it, so it will not work and we will get the error "zsh: : parameter not set".
    (writeShellScriptBin "parrot" ''
      ${builtins.readFile ./scripts/parrot.sh}
    '')
    (writeShellScriptBin "unleash-the-keys" ''
#!/usr/bin/env bash
#
# Add SSH keys from well know SSH directory to the ssh-agent.
# We need to add the SSH keys for:
# - connecting to remote servers in SSH (duh)
# - signing git commits
# - pull/push git changes to remote server
# src: https://stackoverflow.com/questions/13033799/how-to-make-ssh-add-read-passphrase-from-a-file/52671286#52671286
#

set -euo pipefail

BW_SESSION=""
BLUE="\e[1;30;44m"
NC="\e[0m"

info() {
  echo -e "$BLUE I $NC $1"
}

add_ssh_key() {
  local ssh_key_filepath="$1"
  local ssh_key_filename="$(basename $ssh_key_filepath)"

  info "Adding ssh key $ssh_key_filepath to ssh-agent."
  if [[ $ssh_key_filename == '${userSettings.username}' ]]; then
    # Fetch passphrase from bitwarden, then add ssh key to ssh-agent.
    SSH_ASKPASS=parrot \
      ssh-add $ssh_key_filepath \
      <<< "$(bw list items --search ssh@${userSettings.username} | jq -r '.[].fields[].value')"
  else
    ssh-add $ssh_key_filepath
  fi
}

add_ssh_keys() {
  for ssh_key_filepath in $(\
    ls ~/.ssh/* \
    | grep -v config \
    | grep -v allowed_signers \
    | grep -v known_hosts \
    | grep -v pub \
    | grep -v authorized_keys \
  ); do
    add_ssh_key "$ssh_key_filepath";
  done
}

unlock_bw() {
  BW_SESSION="$(bw login --raw || bw unlock --raw)"
  export BW_SESSION
}

unlock_bw
add_ssh_keys
# Display added identities.
ssh-add -l
bw lock
    '')
  ];
}
