#
# Replacement for a shell history which records additional commands
# context with optional encrypted synchronization between machines.
# src: https://github.com/atuinsh/atuin
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ atuin ];

  # Symlink to ~/.config/atuin/config.toml
  xdg.configFile."atuin/config.toml".source = ./.config/atuin/config.toml;
}

