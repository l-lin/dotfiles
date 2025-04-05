#
# Image related tools.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # A command line image viewer for tiling window managers: https://sr.ht/~exec64/imv/
    imv
    # Simple animated GIF screen recorder with an easy to use interface: https://github.com/phw/peek
    peek
  ];
}
