#
# Define the theme options.
#

{ lib, userSettings, ... }: {
  options.theme = with lib; {
    backgroundImage = mkOption {
      type = types.path;
      description = "Background image to set on the monitors.";
    };
    nvimColorScheme = mkOption {
      type = types.str;
      description = "NeoVim color scheme.";
    };
    polarity = mkOption {
      type = types.str;
      description = "Polarity of the theme (dark or light).";
    };
  };

  imports = [
    (./. + "/${userSettings.theme}")
  ];
}
