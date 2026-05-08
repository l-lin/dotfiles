#
# Simple TUI for GH commands
# src: https://codeberg.org/l-lin/lazygh
#

{ config, symlinkRoot, ... }: {
  xdg.configFile."lazygh/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${symlinkRoot}/home-manager/modules/share/vcs/lazygh/.config/lazygh/config.toml";
}
