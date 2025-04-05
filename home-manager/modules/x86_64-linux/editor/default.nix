#
# Editors and IDE.
#

{ pkgs, ...}: {

  home.packages = with pkgs; [
    # A powerful knowledge base that works on top of a local folder of plain text Markdown files: https://obsidian.md/
    obsidian
    # Comprehensive, professional-quality productivity suite, a variant of openoffice.org: https://libreoffice.org/
    libreoffice
    # A simple multi-page document viewer for the MATE desktop: https://mate-desktop.org/
    mate.atril
  ];

  programs = {
    # A highly customizable and functional PDF viewer: https://git.pwmt.org/pwmt/zathura/
    zathura = {
      # Enabling using `programs` instead of `home.packages` so stylix can parameterized its colorscheme.
      enable = true;
    };
  };
}

