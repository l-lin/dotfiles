#
# Image related tools.
#

{ fileExplorer, pkgs, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # The GNU Image Manipulation Program: https://www.gimp.org/
    gimp
    # A command-line application to view images from the terminal written in Rust: https://github.com/atanunq/viu
    viu
  ];

  # ~/.face is used by waybar to set the user icon.
  home.file.".face".source = ./pictures/hi.png;
}
