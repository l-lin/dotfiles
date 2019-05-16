#!/bin/bash

set -e

read -p "Create symlinks? (y/n) " -n 1 -r
echo 
if [[ $REPLY =~ ^[Yy]$ ]]
then
    readonly SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    for file in symlinks/.*; do
        basenameFile=$(basename "${file}")
        [ -r "${file}" ] && [ -f "${file}" ] && rm -f ${HOME}/${basenameFile} && ln -s ${SCRIPT_DIR}/${file} ${HOME}/${basenameFile}
    done

    cp -R .config ~
    cp -R .vim ~
    
    echo
    echo "Remember to execute the following command:"
    echo "      source ~/.zshrc"
fi
