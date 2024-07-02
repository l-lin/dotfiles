#
# Very fast implementation of tldr.
# src: https://github.com/dbrgn/tealdeer
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ tealdeer ];

  # Symlink to ~/.config/tealdeer/config.toml
  xdg.configFile."tealdeer/config.toml".source = ./.config/tealdeer/config.toml;
}
