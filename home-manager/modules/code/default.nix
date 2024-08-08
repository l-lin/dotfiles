#
# Code related stuff.
#

{ fileExplorer, pkgs, ...}: {
  imports = fileExplorer.allSubdirs ./.;

  # NOTE: Work internal tool needs native gcc and make.
  # home.packages = with pkgs; [
  #   # GNU Compiler Collection.
  #   gcc
  #   # Add `make` command.
  #   gnumake
  # ];
}
