#
# Audio stuff.
#

{ pkgs, ... }: {

  home.packages = with pkgs; [
    # PulseAudio Volume Control GUI.
    pavucontrol
  ];
}
