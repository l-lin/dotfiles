#
# Define the theme options.
#

{ userSettings, ... }: {
  imports = [
    (./. + "/${userSettings.theme}")
  ];
}
