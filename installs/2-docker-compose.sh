#!/usr/bin/env bash

set -eu

docker_compose_version="2.5.0"

docker_config_folder=${HOME}/.docker
docker_plugins_folder="${docker_config_folder}/cli-plugins"

mkdir -p ${docker_plugins_folder}

if [ -f ${docker_plugins_folder}/docker-compose ]; then
  echo "[-] docker compose already exists => skipping"
else
  echo "[-] installing docker compose: https://github.com/docker/compose"
  curl -o "${docker_plugins_folder}/docker-compose" \
    -L "https://github.com/docker/compose/releases/download/v${docker_compose_version}/docker-compose-$(uname -s)-$(uname -m)"
  chmod +x "${docker_plugins_folder}/docker-compose"
  docker compose version
fi

