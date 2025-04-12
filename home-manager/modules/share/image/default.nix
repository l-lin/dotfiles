#
# Image related tools.
#

{ fileExplorer, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  # ~/.face is used by waybar to set the user icon.
  home.file.".face".source = ./pictures/hi.png;
}
