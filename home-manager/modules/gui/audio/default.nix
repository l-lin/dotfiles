#
# Audio stuff.
#

{ pkgs, ... }: {

  imports = [
    ./spicetify
  ];

  home.packages = with pkgs; [
    # PulseAudio Volume Control GUI.
    pavucontrol
  ];
}
