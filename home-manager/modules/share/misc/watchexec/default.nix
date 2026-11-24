#
# Executes commands in response to file modifications
# src: https://github.com/watchexec/watchexec
#

{ config, symlinkRoot, ... }: {
  xdg.configFile."mise/conf.d/watchexec.toml".source = config.lib.file.mkOutOfStoreSymlink "${symlinkRoot}/home-manager/modules/share/misc/watchexec/.config/mise/conf.d/watchexec.toml";
}
