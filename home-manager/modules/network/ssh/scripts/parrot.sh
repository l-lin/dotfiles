#!/usr/bin/env bash
#
# Script used to repeat what it read from stdin.
# Useful passing passphrase to ssh-add from external file or program execution,
# as `ssh-add` does not read passphrase from stdin.
# E.g.: SSH_ASKPASS=give-ssh-passphrase ssh-add ~/.ssh/id_ed25519 <<< $(bw list items --search ssh@l-lin | jq -r '.[].fields[].value')
# src: https://stackoverflow.com/questions/13033799/how-to-make-ssh-add-read-passphrase-from-a-file/52671286#52671286
#

set -eu

read -r SECRET
echo -n "${SECRET}"
