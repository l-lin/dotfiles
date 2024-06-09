#
# src: https://nixos.wiki/wiki/Zsh
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ zsh ];

  # Symlink ~/.zshenv
  home.file.".zshenv".source = ./config/.zshenv;
  # Symlink ~/.config/zsh
  xdg.configFile.zsh = {
    source = ./config;
    recursive = true;
  };

  # Custom directories configuration: https://github.com/mfaerevaag/wd
  # Symlink to ~/.warprc
  home.file.".warprc".source = ./.warprc;
}
