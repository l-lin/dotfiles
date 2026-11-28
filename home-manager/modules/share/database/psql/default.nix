#
# Postgres CLI.
# src: https://github.com/dbcli/pgcli
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ postgresql pgcli ];

  # Symlink to ~/.psqlrc
  home.file.".psqlrc".source = ./.psqlrc;

  # Symlink to ~/.config/pgcli/config
  xdg.configFile."pgcli/config".source = ./.config/pgcli/config;
}
