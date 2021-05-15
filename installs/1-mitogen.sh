#!/usr/bin/env bash

set -eu

mitogen_version="0.2.9"

if [ -d "$HOME/apps/mitogen-${mitogen_version}" ]; then
  echo "[-] mitogen already exists => skipping"
else
  echo "[-] installing mitogen: https://mitogen.networkgenomics.com"
  curl -L -o "/tmp/mitogen-${mitogen_version}.tar.gz" "https://networkgenomics.com/try/mitogen-${mitogen_version}.tar.gz"

  pushd "${HOME}/apps"
  tar xzvf "/tmp/mitogen-${mitogen_version}.tar.gz"
  ln -s "${HOME}/apps/mitogen-${mitogen_version}" "${HOME}/apps/mitogen"
  popd
fi

