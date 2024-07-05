#!/usr/bin/env bash
# Script that will create the files needed for nix-direnv to work on the current directory:
# - .envrc
# - flake.nix
# src: https://github.com/nix-community/nix-direnv/wiki/Shell-integration

set -eu

if [ ! -f .envrc ]; then
  cat << EOF > .envrc
use flake
dotenv_if_exists
EOF
  direnv allow
fi

if [ ! -e flake.nix ]; then
  cat <<EOF > flake.nix
{
  description = "A basic flake with a shell";

  # src:
  # - https://nix.dev/tutorials/first-steps/towards-reproducibility-pinning-nixpkgs
  # - https://unix.stackexchange.com/questions/741682/how-to-pin-a-package-version-with-nix-shell
  # Use latest nixpkgs.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  # Or if you need to pin a specific version, take one from:
  # - https://status.nixos.org/ to pin nixpkgs revision for reproducticible Nix expression
  # - https://lazamar.co.uk/nix-versions/ to find revision for a specific tool version
  #inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.\${system};

        # If you need to perform some customization, you can override it like this:
        #customPkgs = (import nixpkgs {
        #  inherit system;
        #  config = {
        #    allowBroken = true;
        #    # Allow insecure package, see https://discourse.nixos.org/t/allow-insecure-packages-in-flake-nix/34655/2.
        #    permittedInsecurePackages = [
        #      "foo"
        #    ];
        #  };
        #});
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # Use to be able to call "make".
            gnumake
            # add your packages here
          ];

          # Add your environment variables here, or create a .env file.
          #THIS_IS_AN_ENV_VAR = "Hello";
        };
      });
}
EOF
  ${EDITOR:-nvim} flake.nix
fi