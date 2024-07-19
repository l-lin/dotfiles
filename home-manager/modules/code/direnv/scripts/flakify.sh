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
  touch flake.nix
  # flake.nix must be tracked by git, otherwise it will not be picked up by direnv...
  git add flake.nix
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
  #inputs.nixpkgs.url = "github:NixOS/nixpkgs/3b24ff7508fc76bfcd203d50a37793ada396ca39";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system:
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

      # If you only need to allowUnfree, you can do it in one-liner (but above still works):
      #pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    in {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          # Run arbitrary commands when files change.
          entr
          # A handy way to save and run project-specific commands.
          just
          # CLI tool to insert spacers when command output stops.
          spacer
          # add your packages here

          # If you need to install some python packages, uncomment the following, and install with `shellHook`.
          #python3
          #python3Packages.pip
          #python3Packages.virtualenv
        ];

        # Add your environment variables here, or create a .env file.
        #THIS_IS_AN_ENV_VAR = "Hello";

        # If you need to perform some shell scripting:
        #shellHook = ''
        #  # Create a virtual environment in the .venv directory
        #  if [ ! -d .venv ]; then
        #    virtualenv .venv
        #  fi

        #  # Activate the virtual environment
        #  source .venv/bin/activate

        #  if [ ! type presenterm-export >/dev/null 2>&1 ]; then
        #    pip install presenterm-export
        #  fi

        #  echo "Virtual environment activated. Use 'deactivate' to exit."
        #'';
      };
    }
  );
}
EOF
  ${EDITOR:-nvim} flake.nix
fi
