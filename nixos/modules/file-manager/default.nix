#
# File manager.
#

{ fileExplorer, ... }: {
  imports = fileExplorer.allSubdirs ./.;
}
