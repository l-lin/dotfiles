#
# Other stuff I can't categorize.
#

{ fileExplorer, ... }: {
  imports = fileExplorer.allSubdirs ./.;
}
