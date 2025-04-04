#
# i3-like tiling window manager for macOS.
# src: https://github.com/nikitabobko/AeroSpace
#

{ fileExplorer, ... }: {
  # Aerospace.app is not available in Spotlight / Raycast when installed from
  # home-manager. Not sure why.
  # => Manually install Aerspace.
  # programs.aerospace = {
  #   enable = true;
  # };

  imports = fileExplorer.allSubdirs ./.;
}
