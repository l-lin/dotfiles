#!/usr/bin/env bash

set -eu

git_lfs_version="3.3.0"
link_url="https://github.com/git-lfs/git-lfs/releases/download/v${git_lfs_version}/git-lfs-linux-amd64-v${git_lfs_version}.tar.gz"
target_file="/tmp/git_lfs.tar.gz"
src_folder="/tmp/git_lfs"

git lfs >/dev/null 2>&1
has_git_lfs=$?

if [[ ${has_git_lfs} == 0 ]]; then
  echo "[-] git lfs already exists => skipping"
else
  echo "[-] installing git LFS:https://git-lfs.com/"
  curl -L -o "${target_file}" "${link_url}"
  mkdir -p "${src_folder}"
  tar xzvf "${target_file}" --directory="${src_folder}"
  sudo "${src_folder}/git-lfs-${git_lfs_version}/install.sh"

  rm "${target_file}"
  rm -rf "${src_folder}"
fi

