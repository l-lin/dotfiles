#
# Image related tools.
#

{ fileExplorer, pkgs, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # Powerful yet simple to use screenshot software: https://github.com/flameshot-org/flameshot
    flameshot
    # The GNU Image Manipulation Program: https://www.gimp.org/
    gimp
    # A command line image viewer for tiling window managers: https://sr.ht/~exec64/imv/
    imv
    # Simple animated GIF screen recorder with an easy to use interface: https://github.com/phw/peek
    peek
    # A command-line application to view images from the terminal written in Rust: https://github.com/atanunq/viu
    viu
  ];

  # ~/.face is used by waybar to set the user icon.
  home.file.".face".source = ./pictures/hi.png;
}
