#!/usr/bin/env bash

set -eu

pet_version="0.3.6"

if type pet >/dev/null 2>&1; then
  echo "[-] pet already exists => skipping"
else
  echo "[-] installing pet: https://github.com/knqyf263/pet#debian-ubuntu"
  curl -L -o /tmp/pet.deb https://github.com/knqyf263/pet/releases/download/v${pet_version}/pet_${pet_version}_linux_amd64.deb
  sudo dpkg -i /tmp/pet.deb
fi

