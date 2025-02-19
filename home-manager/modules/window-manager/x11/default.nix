#
# X11 window system protocol.
# src: https://www.x.org/wiki/
#

{ pkgs, userSettings, ... }: {
  imports = [
    ./redshift
    (./. + "/${userSettings.wm}")
  ];

  home.packages = with pkgs; [
    # X11 screen lock utility with security in mind: https://github.com/google/xsecurelock
    # TODO: Not working well...
    #xsecurelock
    # Resize and Rotate for X window manager: https://wiki.archlinux.org/title/Xrandr
    xorg.xrandr
    # Command-line program for getting and setting the contents of the X selection: http://www.kfish.org/software/xsel
    xsel
  ];

  home.sessionVariables = {
    XSECURELOCK_SAVER = "saver_blank xsecurelock";
    XSECURELOCK_PASSWORD_PROMPT = "asterisks";
  };
}
