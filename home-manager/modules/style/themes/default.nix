#
# Define the theme options.
#

{ lib, userSettings, ... }: {
  options.theme = with lib; {
    backgroundImage = mkOption {
      type = types.path;
      description = "Background image to set on the monitors.";
    };
  };

  imports = [
    (./. + "/${userSettings.theme}")
  ];
}
