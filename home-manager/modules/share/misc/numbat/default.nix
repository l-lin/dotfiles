#
# High precision scientific calculator with full support for physical units.
# src: https://numbat.dev/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ numbat ];

  # Symlink to ~/.config/numbat/config.toml.
  xdg.configFile = pkgs.lib.mkIf (!pkgs.stdenv.isDarwin) {
    "numbat/config.toml".source = ./.config/numbat/config.toml;
  };

  # Symlink to ~/Library/Application Support/numbat/config.toml for macOS support.
  home.file = pkgs.lib.mkIf pkgs.stdenv.isDarwin {
    "Library/Application Support/numbat/config.toml".source = ./.config/numbat/config.toml;
  };
}
