#
# The Go Programming language
# src: https://go.dev/
# NOTE: Using mise to install Go because I want to install 3rd party tools with mise.
#

{ config, symlinkRoot, ... }: {
  xdg.configFile."mise/conf.d/go.toml".source = config.lib.file.mkOutOfStoreSymlink "${symlinkRoot}/home-manager/modules/share/code/go/.config/mise/conf.d/go.toml";
}
