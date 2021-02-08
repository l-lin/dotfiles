#!/usr/bin/env bash

set -eu

echo "[-] Creating folders..."
mkdir -p $HOME/apps
mkdir -p $HOME/bin
mkdir -p $HOME/work
mkdir -p $HOME/perso
mkdir -p $HOME/.zsh/completion
mkdir -p $HOME/go
mkdir -p $HOME/.undodir

./bootstrap.sh

for f in installs/*.sh; do
  ./$f
done

echo "[-] installations complete!"

