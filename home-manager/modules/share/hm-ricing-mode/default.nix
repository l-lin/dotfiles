#
# Ricing mode utility for Home Manager 
# src: https://github.com/mipmip/hm-ricing-mode
#

{ symlinkRoot, ... }: {
  programs.hm-ricing-mode = {
    enable = true;
    apps = {
      ai = {
        dest_dir = ".config/ai";
        source_dir = "${symlinkRoot}/home-manager/modules/share/ai/.config/ai";
        # symlink | backport (default)
        type = "symlink";
      };
      pi = {
        dest_dir = ".pi/agent/extensions";
        source_dir = "${symlinkRoot}/home-manager/modules/share/ai/pi/.pi/agent/extensions";
        type = "symlink";
      };
      zsh = {
        dest_dir = ".config/zsh";
        source_dir = "${symlinkRoot}home-manager/modules/share/shell/zsh/.config/zsh";
        type = "symlink";
      };
    };
  };
}
