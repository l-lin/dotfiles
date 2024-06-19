#
# Cloud related stuff.
#

{ fileExplorer, ... }: {
  imports = fileExplorer.allSubdirs ./.;
}
