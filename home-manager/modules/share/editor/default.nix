#
# Editors and IDE.
#

{ fileExplorer, ...}: {
  imports = fileExplorer.allSubdirs ./.;

  programs = {
    # A highly customizable and functional PDF viewer: https://git.pwmt.org/pwmt/zathura/
    zathura = {
      # Enabling using `programs` instead of `home.packages` so stylix can parameterized its colorscheme.
      enable = true;
    };
  };
}
