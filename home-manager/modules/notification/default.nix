#
# Because we are living in a busy world, so we need notifications everywhere.
#

{ fileExplorer, ... }: {
  imports = fileExplorer.allSubdirs ./.;
}
