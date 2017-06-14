#!/bin/bash

read -p "Create/override dotfiles? (y/n) " -n 1 -r
echo 
if [[ $REPLY =~ ^[Yy]$ ]]
then
    rsync -poghb --backup-dir=/tmp/rsync -e /dev/null --progress \
        --exclude "bootstrap.sh" \
        --exclude "dotfiles.gif" \
        --exclude ".git/" \
        --exclude "idea" \
        --exclude "README.md" \
        --exclude "sublimetext/" \
        --exclude "install.sh" \
        -av -- . ~
    echo
    echo "Remember to execute the following command:"
    echo "      source ~/.zshrc"
fi
