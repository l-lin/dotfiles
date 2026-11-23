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
  # - font-size: Rex → Settings → Terminal → Typography → Font size (18pt)
  # - Rex → Settings → Themes → Import Theme
  #
}
