#
# Define the theme options.
# To add a new theme, you have to:
#
# - create home-manager/style/themes/<theme>/default.nix
# - create home-manager/style/themes/<theme>/colorscheme.yaml
#   - you can fetch the colors from https://github.com/tinted-theming/schemes/tree/spec-0.11/base16
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
    nvimColorSchemePluginLua = mkOption {
      type = types.str;
      description = "NeoVim color scheme plugin in Lua.";
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
