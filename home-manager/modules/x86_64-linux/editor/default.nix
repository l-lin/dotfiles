#
# Editors and IDE.
#

{ pkgs, ...}: {

  home.packages = with pkgs; [
    # Comprehensive, professional-quality productivity suite, a variant of openoffice.org: https://libreoffice.org/
    libreoffice
    # A simple multi-page document viewer for the MATE desktop: https://mate-desktop.org/
    mate.atril
  ];
}

