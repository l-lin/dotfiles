#
# Modules for gnome.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # GSettings editor for GNOME: https://apps.gnome.org/DconfEditor/
    dconf-editor
    # A simple color chooser written in GTK3: https://gitlab.gnome.org/World/gcolor3
    gcolor3
    # Gnome tweaks to change caps lock to Ctrl: https://gitlab.gnome.org/GNOME/gnome-tweaks
    gnome-tweaks
    # Copy/paste utilities: https://github.com/bugaevc/wl-clipboard
    wl-clipboard
  ];
}
