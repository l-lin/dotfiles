#
# Code related stuff.
#

{ fileExplorer, pkgs, ...}: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # Maintained ctags implementation: https://docs.ctags.io/en/latest/
    universal-ctags

    # Parser generator tool and an incremental parsing library: https://github.com/tree-sitter/tree-sitter
    tree-sitter
  # HACK: DISABLED because work internal tool needs native gcc and make.
  #   # GNU Compiler Collection.
  #   gcc
  #   # Add `make` command.
  #   gnumake
  ];
}
