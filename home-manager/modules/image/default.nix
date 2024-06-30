#
# Image related tools.
#

{ pkgs, ... }: {
  imports = [
    ./satty
    ./wallpaper
  ];

  home.packages = with pkgs; [
    # A wlroots-compatible Wayland color picker that does not suck.
    #
    # /!\ Need to set the cursor theme for hyprpicker to work.
    # See https://github.com/hyprwm/hyprpicker/issues/51.
    # Cursor set in `theme/default.nix`.
    #
    # src: https://github.com/hyprwm/hyprpicker
    hyprpicker
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
