#
# Postgres CLI.
# src: https://github.com/dbcli/pgcli
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ pgcli ];

  # Symlink to ~/.psqlrc
  home.file.".psqlrc".source = ./.psqlrc;
}
