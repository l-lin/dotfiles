#
# Best text editor in the world!
# src: https://neovim.io/
#

{ pkgs, ... }: {
  # https://mynixos.com/nixpkgs/options/programs.neovim
  programs.neovim = {
    enable = true;

    # Symlink vi and vim to nvim binary.
    viAlias = true;
    vimAlias = true;

    withRuby = true;
    withNodeJs = true;
    withPython3 = true;
  };

  # Symlink ~/.config/nvim
  xdg.configFile.nvim = {
    source = ./config;
    recursive = true;
  };

  # Symlink ~/.local/share/eclipse/java-code-style.xml
  home.file.".local/share/eclipse/java-code-style.xml".source = ./java-code-style.xml;
}
