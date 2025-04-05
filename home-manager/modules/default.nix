#
# Modules to install and configure at user level.
#

{ systemSettings, ... }: {
  imports = [
    ./share
    ./${systemSettings.system}
  ];
}
