#
# Cloud related stuff.
#

{ fileExplorer, pkgs, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # Tool for building, changing, and versioning infrastructure: https://www.terraform.io/
    terraform
  ];
}
