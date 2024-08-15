#
# Amazon Web Services.
# src: https://aws.amazon.com/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Unified tool to manage your AWS services. https://aws.amazon.com/cli/
    awscli2

    # Script to invoke bitwarden CLI to get AWS credentials.
    (writeShellScriptBin "aws-bw" ''
      ${builtins.readFile ./scripts/aws-bw.sh}
    '')
  ];
}
