{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Gnome tweaks to change caps lock to Ctrl.
    gnome.gnome-tweaks
  ];
}
