#!/usr/bin/env zsh
#
# Load secrets env only once.
#

if [ -n "$__SECRETS_SOURCED" ]; then return; fi
export __SECRETS_SOURCED=1

for f in "${ZDOTDIR}"/secrets/.secrets*; do
  source "${f}"
done
