#!/usr/bin/env zsh

set -eu

java_id="adoptopenjdk-11.0.10+9"

if type java >/dev/null 2>&1; then
  echo "[-] java already installed => skipping"
else
  echo "[-] installing Java ${java_id}"
  asdf plugin add java
  asdf install java "${java_id}"
  asdf global java "${java_id}"
fi

