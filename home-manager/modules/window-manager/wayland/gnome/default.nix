#
# Desktop environment.
# src: https://www.gnome.org/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Gnome tweaks to change caps lock to Ctrl.
    gnome-tweaks
  ];
}
