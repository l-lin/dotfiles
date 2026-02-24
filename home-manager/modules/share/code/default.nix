#
# Code related stuff.
#

{ fileExplorer, pkgs, ...}: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # Fast and polyglot tool for code searching, linting, rewriting at large scale: https://ast-grep.github.io/
    ast-grep
    # Syntax-aware diff: https://github.com/Wilfred/difftastic
    difftastic
    # Maintained ctags implementation: https://docs.ctags.io/en/latest/
    universal-ctags
  # HACK: DISABLED because work internal tool needs native gcc and make.
  #   # GNU Compiler Collection.
  #   gcc
  #   # Add `make` command.
  #   gnumake
  ];
}
