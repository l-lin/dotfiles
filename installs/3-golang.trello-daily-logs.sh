#!/usr/bin/env bash

set -eu

if type trello-daily-logs >/dev/null 2>&1; then
  echo "[-] trello-daily-logs already exists => skipping"
else
  echo "[-] installing trello-daily-logs: https://github.com/l-lin/trello-daily-logs"
  go get github.com/l-lin/trello-daily-logs
  asdf reshim golang
fi

