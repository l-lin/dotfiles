#
# Modules to install and configure at user level.
#

{ fileExplorer, ... }: {
  imports = fileExplorer.allSubdirs ./.;
}
