#
# Editors and IDE.
#

{ fileExplorer, ...}: {
  imports = fileExplorer.allSubdirs ./.;
}
