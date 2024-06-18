#
# Modules to install and configure at system level.
#

{ fileExplorer, ... }: {
  imports = fileExplorer.allSubdirs ./.;
}
