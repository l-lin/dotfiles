#
# An hyperland plugin system.
# src: https://github.com/hyprland-community/pyprland
#

{ pkgs, userSettings, ... }: {
  home.packages = with pkgs; [ pyprland ];

  xdg.configFile."hypr/pyprland.toml".text = ''
[pyprland]
plugins = ["scratchpads"]

[scratchpads.audio_mixer]
command = "${userSettings.term} --class scratchpad -e pulsemixer"
margin = 50
unfocus = "hide"
animation = "fromTop"
lazy = true

[scratchpads.calculator]
command = "${userSettings.term} --class scratchpad -e numbat"
margin = 50
unfocus = "hide"
animation = "fromTop"
lazy = true

[scratchpads.calendar]
command = "${userSettings.term} --class scratchpad -e calcure"
margin = 50
unfocus = "hide"
animation = "fromTop"
lazy = true

[scratchpads.file_manager]
command = "${userSettings.term} --class scratchpad -e ${userSettings.fileManager}"
margin = 50
unfocus = "hide"
animation = "fromTop"
lazy = true

[scratchpads.terminal]
command = "${userSettings.term} --class scratchpad"
margin = 50
unfocus = "hide"
animation = "fromTop"
lazy = true
  '';
}
