#
# Warp keybinding was removed from wd plugin. Let's bring it back!
# src: https://github.com/mfaerevaag/wd/pull/134
#

{ config, symlinkRoot, ... }: {
  xdg.configFile = {
    "zsh/plugins/wd.antidote".source = ./.config/zsh/plugins/wd/wd.antidote;
    "zsh/plugins/wd.plugin.zsh".source = ./.config/zsh/plugins/wd/wd.plugin.zsh;
  };
  # mkOutOfStoreSymlink creates a mutable symlink (writable at runtime).
  # wd modifies .warprc when adding/removing warp points.
  home.file.".warprc".source = config.lib.file.mkOutOfStoreSymlink "${symlinkRoot}/home-manager/modules/share/misc/wd/.warprc";
}
