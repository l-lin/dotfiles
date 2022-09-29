#!/usr/bin/env bash

set -eu

if type kafkactl >/dev/null 2>&1; then
  echo "[-] kafkactl already installed => skipping"
else
  echo "[-] installing kafkactl"
  sudo snap install kafkactl
fi

