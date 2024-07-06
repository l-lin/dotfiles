#!/usr/bin/env bash
#
# Enable passing passphrase to ssh-add from external file or program execution.
# src: https://stackoverflow.com/questions/13033799/how-to-make-ssh-add-read-passphrase-from-a-file/52671286#52671286
#

set -eu

# Fetch passphrase from bitwarden, then add ssh key to ssh-agent.
SSH_ASKPASS=give-ssh-passphrase \
  ssh-add ~/.ssh/id_ed25519 \
  <<< "$(bw list items --search ssh@l-lin | jq -r '.[].fields[].value')"

# Display added identities.
ssh-add -l
