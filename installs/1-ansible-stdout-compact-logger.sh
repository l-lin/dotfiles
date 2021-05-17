#!/usr/bin/env bash

set -eu

if [ -d "$HOME/apps/ansible_stdout_compact_logger" ]; then
  echo "[-] ansible stdout compact logger already exists => skipping"
else
  echo "[-] installing ansible stdout compact logger: https://github.com/octplane/ansible_stdout_compact_logger"

  git clone https://github.com/octplane/ansible_stdout_compact_logger "${HOME}/apps/ansible_stdout_compact_logger"
fi

