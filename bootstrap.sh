#!/bin/bash

set -e

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
    	home_file_dir=$(realpath $(dirname ${HOME}/${file}))
    	dotfiles_file_dir=$(realpath $(dirname ${symlinks_dir}/${file}))
        if [ ! -d ${home_file_dir} ]; then
            mkdir -p ${home_file_dir}
        fi
        [ -r "${file}" ] && [ -f "${file}" ] && \
            rm -f ${home_file_dir}/${basename_file} && \
            ln -s ${dotfiles_file_dir}/${basename_file} ${home_file_dir}/${basename_file}
    done

    echo
    echo "Remember to execute the following command:"
    echo "      source ~/.zshrc"
fi
