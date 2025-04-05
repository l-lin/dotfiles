#
# Editors and IDE.
#

{ fileExplorer, pkgs, ...}: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
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
