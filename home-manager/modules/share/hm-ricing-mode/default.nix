#
# Ricing mode utility for Home Manager 
# src: https://github.com/mipmip/hm-ricing-mode
#

{ symlinkRoot, ... }: {
  programs.hm-ricing-mode = {
    enable = true;
    apps = {
      pi = {
        dest_dir = ".pi/agent/extensions";
        source_dir = "${symlinkRoot}/home-manager/modules/share/ai/pi/.pi/agent/extensions";
        # symlink | backport (default)
        type = "symlink";
      };
    };
  };
}
