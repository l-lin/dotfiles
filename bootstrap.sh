#!/bin/bash

set -eu

read -p "Create symlinks? (y/n) " -n 1 -r
echo 
if [[ $REPLY =~ ^[Yy]$ ]]
then
    readonly script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    symlinks_dir=${script_dir}/symlinks
    cd ${symlinks_dir}
    for file in $(find . -type f); do
      echo "[-] processing ${file}"
      basename_file=$(basename "${file}")
      home_file_dir=$(dirname ${HOME}/${file})
      mkdir -p ${home_file_dir}
      dotfiles_file_dir=$(realpath $(dirname ${symlinks_dir}/${file}))
      [ -r "${file}" ] && [ -f "${file}" ] && \
          rm -f ${home_file_dir}/${basename_file} && \
          ln -s ${dotfiles_file_dir}/${basename_file} ${home_file_dir}/${basename_file}
    done

    echo
    echo "Remember to execute the following command:"
    echo "      source ~/.zshrc"
fi
