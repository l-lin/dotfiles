#
# Code related stuff.
#

{ fileExplorer, ...}: {
  imports = fileExplorer.allSubdirs ./.;

  # HACK: DISABLED because work internal tool needs native gcc and make.
  # home.packages = with pkgs; [
  #   # GNU Compiler Collection.
  #   gcc
  #   # Add `make` command.
  #   gnumake
  # ];
}
