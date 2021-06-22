#!/usr/bin/env zsh

set -eu

sbt_id="1.5.4"

if type sbt >/dev/null 2>&1; then
  echo "[-] sbt already installed => skipping"
else
  echo "[-] installing sbt ${sbt_id}"
  asdf plugin add sbt
  asdf install sbt "${sbt_id}"
  asdf global sbt "${sbt_id}"
fi

