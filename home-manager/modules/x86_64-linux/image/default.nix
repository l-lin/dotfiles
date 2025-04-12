#
# Image related tools.
#

{ fileExplorer, pkgs, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # The GNU Image Manipulation Program: https://www.gimp.org/
    gimp
    # A command line image viewer for tiling window managers: https://sr.ht/~exec64/imv/
    imv
    # Simple animated GIF screen recorder with an easy to use interface: https://github.com/phw/peek
    peek
    # A command-line application to view images from the terminal written in Rust: https://github.com/atanunq/viu
    viu
  ];
}
