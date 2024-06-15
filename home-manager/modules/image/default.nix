#
# Image related tools.
#

{ pkgs, ... }: {
  imports = [
    ./satty
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
    # Wallpaper tool for Wayland conpositors: https://github.com/swaywm/swaybg
    swaybg
  ];

  # ~/.face is used by waybar to set the user icon.
  home.file.".face".source = ./config/hi.png;
  home.file."Pictures/cat.jpg".source = ./config/cat.jpg;
  home.file."Pictures/hi.png".source = ./config/hi.png;
  home.file."Pictures/summer-dark.png".source = ./config/summer-dark.png;
  home.file."Pictures/summer-light.png".source = ./config/summer-light.png;
}
