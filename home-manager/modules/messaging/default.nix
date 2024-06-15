#
# Messaging tools.
#

{ fileExplorer, ... }: {
  imports = fileExplorer.allSubdirs ./.;
}
