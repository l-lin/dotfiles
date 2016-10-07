#!/bin/bash

read -p "Create/override dotfiles? (y/n) " -n 1 -r
echo 
if [[ $REPLY =~ ^[Yy]$ ]]
then
    rsync -poghb --backup-dir=/tmp/rsync -e /dev/null --progress --exclude ".git/" --exclude "bootstrap.sh" --exclude "README.md" --exclude "sublimetext/" --exclude "idea" --exclude "vscode" -av -- . ~
    echo
    echo "Remember to execute the following command:"
    echo "      source ~/.zshrc"
fi
