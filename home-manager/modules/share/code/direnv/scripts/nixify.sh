#!/usr/bin/env bash
# Script that will create the files needed for nix-direnv to work on the current directory:
# - .envrc
# - shell.nix
# src: https://github.com/nix-community/nix-direnv/wiki/Shell-integration

set -eu

if [ ! -f .envrc ]; then
  cat << EOF > .envrc
use nix
dotenv_if_exists
EOF
  direnv allow
fi

if [ ! -f shell.nix ]; then
  cat << EOF > shell.nix
# src:
# - https://nix.dev/tutorials/first-steps/towards-reproducibility-pinning-nixpkgs
# - https://unix.stackexchange.com/questions/741682/how-to-pin-a-package-version-with-nix-shell

# Use latest nixpkgs.
{ pkgs ? import <nixpkgs> {}}:

# Or if you need to pin a specific version, take one from:
# - https://status.nixos.org/ to pin nixpkgs revision for reproducticible Nix expression
# - https://lazamar.co.uk/nix-versions/ to find revision for a specific tool version
#{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/93fbfcd45e966ea1cff043d48bd45d1285082770.tar.gz") {}}:

pkgs.mkShell {
  packages = with pkgs; [
    # add your packages here
  ];
}

# If you need to export some environment variables, you can create a .env file and put them there.
# They will be loaded automatically.


# If you need multiple tools with specific revision, you can import multiple nixpkgs.
#let
#  gitPkgsRevision = "0c159930e7534aa803d5cf03b27d5c86ad6050b7"; # git 2.16.2
#  htopPkgsRevision = "5ed9176c52e4ceed2755a19b3e8357a0772de8ff"; # htop 2.0.0
#  pkgsForGit = import (builtins.fetchTarball {
#    url = "https://github.com/NixOS/nixpkgs/archive/\${gitPkgsRevision}.tar.gz";
#  }) {};
#  pkgsForHtop= import (builtins.fetchTarball {
#    url = "https://github.com/NixOS/nixpkgs/archive/\${htopPkgsRevision}.tar.gz";
#  }) {};
#in
#
#pkgsForGit.mkShell {
#  packages = [
#    pkgsForGit.git
#    pkgsForHtop.htop
#  ];
#}
EOF
  ${EDITOR:-nvim} shell.nix
fi

