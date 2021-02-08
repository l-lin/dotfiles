#!/usr/bin/env bash

set -eu

docker_compose_version="1.25.5"

if type docker-compose >/dev/null 2>&1; then
  echo "[-] docker-compose already exists => skipping"
else
  echo "[-] installing docker-compose: https://github.com/docker/compose"
  sudo curl -o /usr/local/bin/docker-compose -L https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-`uname -s`-`uname -m`
  sudo chmod +x /usr/local/bin/docker-compose
  docker-compose -version
fi

