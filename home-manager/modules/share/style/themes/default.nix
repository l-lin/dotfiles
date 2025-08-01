#
# Define the theme options.
# To add a new theme, you have to:
#
# - create home-manager/share/style/themes/<theme>/default.nix
# - create home-manager/share/style/themes/<theme>/colorscheme.yaml
#   - you can fetch the colors from https://github.com/tinted-theming/schemes/tree/spec-0.11/base16
#

{ lib, userSettings, ... }: {
  options.theme = with lib; {
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
