#
# Fonts management in home-manager.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Iconic font aggregator, collection, & patcher. 3,600+ icons, 50+ patched fonts: https://nerdfonts.com/
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];
}
