#
# AI related stuff.
#

{ fileExplorer, ... }: {
  imports = fileExplorer.allSubdirs ./.;
}
