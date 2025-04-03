#
# Editors and IDE.
#

{ fileExplorer, pkgs, ...}: {
  imports = fileExplorer.allSubdirs ./.;

  # TODO: Install Linux package only if Linux.
  home.packages = with pkgs; [
    # Comprehensive, professional-quality productivity suite, a variant of openoffice.org: https://libreoffice.org/
    #libreoffice
    # A simple multi-page document viewer for the MATE desktop: https://mate-desktop.org/
    #mate.atril
    # A powerful knowledge base that works on top of a local folder of plain text Markdown files: https://obsidian.md/
    obsidian
  ];

  programs = {
    # A highly customizable and functional PDF viewer: https://git.pwmt.org/pwmt/zathura/
    zathura = {
      # Enabling using `programs` instead of `home.packages` so stylix can parameterized its colorscheme.
      enable = true;
    };
  };
}
