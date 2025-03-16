#
# Communication tools.
#

{ fileExplorer, ... }: {
  imports = fileExplorer.allSubdirs ./.;
}
