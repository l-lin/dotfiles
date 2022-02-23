#!/usr/bin/env zsh

set -eu

minikube="1.25.1"

if type minikube >/dev/null 2>&1; then
  echo "[-] minikube already installed => skipping"
else
  echo "[-] installing minikube ${minikube}"
  asdf plugin add minikube
  asdf install minikube "${minikube}"
  asdf global minikube "${minikube}"
fi

