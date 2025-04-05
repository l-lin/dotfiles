#
# i3-like tiling window manager for macOS.
# Installed from brew in nix-darwin/apps.nix.
# src: https://github.com/nikitabobko/AeroSpace
#

{ fileExplorer, ... }: {
  imports = fileExplorer.allSubdirs ./.;
}
