#
# Tools only used in Wayland.
#

{ fileExplorer, ... }: {
  imports = fileExplorer.allSubdirs ./.;
}
