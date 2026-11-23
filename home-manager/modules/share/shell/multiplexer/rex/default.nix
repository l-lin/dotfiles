#
# src: https://www.superlogical.com/rex
#

{ config, symlinkRoot, ... }: {
  xdg.configFile = {
    "rex" = {
      source = config.lib.file.mkOutOfStoreSymlink "${symlinkRoot}/home-manager/modules/share/shell/multiplexer/rex/.config/rex";
      recursive = true;
    };

    "zsh/plugins/rex" = {
      source = ./.config/zsh/plugins/rex;
      recursive = true;
    };
  };

  #
  # There's no settings files for now. So everything must be set directly in the GUI:
  # - font-size: Rex > Settings > Terminal > Typography → Font size (18pt)
  # - theme: Rex > Settings > Themes > Import Theme > Select "home-manager/modules/share/shell/multiplexer/rex/.config/rex/themes/grey"
  # - pi cursor display: Rex Settings > Interface > Panes > Customize panes > Padding > Fill with program colors to Off
  # - Go to Anything: Settings > Developer > Experimental Feature > New Quick Switcher
  #
}
