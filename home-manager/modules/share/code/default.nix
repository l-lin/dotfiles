#
# Code related stuff.
#

{ fileExplorer, pkgs, ...}: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # Maintained ctags implementation: https://docs.ctags.io/en/latest/
    universal-ctags
  # HACK: DISABLED because work internal tool needs native gcc and make.
  #   # GNU Compiler Collection.
  #   gcc
  #   # Add `make` command.
  #   gnumake
  ];
}
