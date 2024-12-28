#
# Amazon Web Services.
# src: https://aws.amazon.com/
#

{ pkgs, ... }:
let
  # FIXME: nixos-unstable currently does not have the fix on awscli2
  # (https://github.com/NixOS/nixpkgs/pull/367979). So I'm pinning the current
  # master branch for awscli2.
  # DO NOT forget to revert back to nixos-unstable!
  pkgsForAwsCli2 = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/4fd5f92835f8fe42298736f8ccbf5b4b4b6f6958.tar.gz";
    sha256 = "1nafrdmwfw0h9fc6pjwmqmnndzfh33564vj47zx5bwj098pgv5gd";
  }) { inherit (pkgs) system; };
in {
  home.packages = [
    # Unified tool to manage your AWS services. https://aws.amazon.com/cli/
    pkgsForAwsCli2.awscli2

    # Script to invoke bitwarden CLI to get AWS credentials.
    (pkgs.writeShellScriptBin "aws-bw" ''
      ${builtins.readFile ./scripts/aws-bw.sh}
    '')
  ];
}
