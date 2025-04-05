#
# Other stuff I can't categorize.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Show battery status and other ACPI information: https://sourceforge.net/projects/acpiclient/
    acpi
    # A CLI utility for displaying current network utilization: https://github.com/imsnif/bandwhich
    bandwhich
    # A menu-driven bash script for the management of removable media with udisks: https://github.com/jamielinux/bashmount
    bashmount
    # Read and control device brightness: https://github.com/Hummer12007/brightnessctl
    brightnessctl

    # GNU implementation of the `tar' archiver: https://www.gnu.org/software/tar/
    gnutar
 
    # Send desktop notifications: https://gitlab.gnome.org/GNOME/libnotify
    libnotify
    # Tools for reading hardware sensors: https://hwmon.wiki.kernel.org/lm_sensors
    lm_sensors
    # A set of tools for controlling the network subsystem in Linux: http://net-tools.sourceforge.net/
    nettools
    # Stores, retrieves, generates, and synchronizes passwords securely: https://www.passwordstore.org/
    pass-wayland
    # A log file highlighter: https://github.com/bensadeh/tailspin
    tailspin
  ];
}

