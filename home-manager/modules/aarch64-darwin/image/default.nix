#
# Image related tools.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Paste image files from clipboard to file on MacOS: https://github.com/jcsalterego/pngpaste
    pngpaste
  ];
}
