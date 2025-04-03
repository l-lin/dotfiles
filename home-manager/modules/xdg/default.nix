#
# Various specifications specify files and file formats. This specification
# defines where these files should be looked for by defining one or more base
# directories relative to which files should be located.
# src:
# - https://wiki.archlinux.org/title/XDG_Base_Directory
# - https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
# - https://mynixos.com/home-manager/options/xdg
#

{
  # TODO: Install only on Linux.
#  xdg = {
#    userDirs = {
#      enable = true;
#      # Create XDG Dirs
#      createDirectories = true;
#    };
#
#    # Let home-manager manage ~/.config/mimeapps.list.
#    # Useful to set the default web browser for example.
#    # HACK: DISABLED because I'm currently using native install of Zen browser.
#    #mimeApps.enable = true;
#  };
}
