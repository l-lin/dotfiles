#
# Amazon Web Services.
# src: https://aws.amazon.com/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Unified tool to manage your AWS services: https://aws.amazon.com/cli/
    awscli2
    # Credential helper for the Docker daemon that makes it easier to use ECR: https://github.com/awslabs/amazon-ecr-credential-helper
    amazon-ecr-credential-helper

    # Script to invoke bitwarden CLI to get AWS credentials.
    (writeShellScriptBin "aws-bw" ''
      ${builtins.readFile ./scripts/aws-bw.sh}
    '')
  ];
}
