#
# Web browser.
#

{ fileExplorer, ... }: {
  imports = fileExplorer.allSubdirs ./.;
}
