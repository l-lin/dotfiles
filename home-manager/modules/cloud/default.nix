#
# Cloud related stuff.
#

{ fileExplorer, ... }: {
  imports = [ ./aws ];
  #imports = fileExplorer.allSubdirs ./.;
}
