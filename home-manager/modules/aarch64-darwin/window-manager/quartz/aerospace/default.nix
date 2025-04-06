#
# i3-like tiling window manager for macOS.
# Installed from brew in nix-darwin/apps.nix.
# src: https://github.com/nikitabobko/AeroSpace
#

{ fileExplorer, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  # Symlink to ~/.config/aerospace/aerospace.toml.
  xdg.configFile."aerospace/aerospace.toml".source = ./.config/aerospace/aerospace.toml;
}
