#
# A high-level dynamically-typed programming language.
# src: https://www.python.org/
# NOTE: Using mise instead, because python version management is hell.
#

{ config, symlinkRoot, ... }: {
  xdg.configFile."mise/conf.d/python.toml".source = config.lib.file.mkOutOfStoreSymlink "${symlinkRoot}/home-manager/modules/share/code/python/.config/mise/conf.d/python.toml";
}
