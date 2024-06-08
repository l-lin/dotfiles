#
# Various specifications specify files and file formats. This specification
# defines where these files should be looked for by defining one or more base
# directories relative to which files should be located. 
#
# See:
# - https://wiki.archlinux.org/title/XDG_Base_Directory
# - https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
# - https://mynixos.com/home-manager/options/xdg
#

{
  xdg = {
    userDirs = {
      enable = true;
      # Create XDG Dirs
      createDirectories = true;
    };
  };
}
