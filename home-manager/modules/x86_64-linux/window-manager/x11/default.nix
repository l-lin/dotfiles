#
# X11 window system protocol.
# src: https://www.x.org/wiki/
#

{ pkgs, userSettings, ... }: {
  imports = [
    ./redshift
    (./. + "/${userSettings.wm}")
  ];

  # HACK: xscreensaver is installed natively because I'm getting some
  # "Permission denied" with the one installed from home-manager.
  # I should investigate it when I have the time...
  #
  # If the authentication fails even with right password, you might need to
  # manually set some permission on a specific file:
  #
  #   chmod u+s /sbin/unix_chkpwd
  #
  # src: https://unix.stackexchange.com/a/422556

  home.packages = with pkgs; [
    # Lightweight color picker for X11: https://github.com/Soft/xcolor
    xcolor
    # Resize and Rotate for X window manager: https://wiki.archlinux.org/title/Xrandr
    xorg.xrandr
    # Command-line program for getting and setting the contents of the X selection: http://www.kfish.org/software/xsel
    xsel
  ];
}
