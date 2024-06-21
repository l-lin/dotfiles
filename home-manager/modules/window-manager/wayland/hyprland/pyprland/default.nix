#
# An hyperland plugin system.
# src: https://github.com/hyprland-community/pyprland
#

{ pkgs, userSettings, ... }: {
  home.packages = with pkgs; [ pyprland ];

  # Symlink to ~/.config/hypr/pyprland.toml
  xdg.configFile."hypr/pyprland.toml".text = ''
[pyprland]
plugins = [
  # Easily toggle the visibility of applications: https://hyprland-community.github.io/pyprland/scratchpads.html.
  "scratchpads",
  # Implements a workspace layout where one window is bigger and centered, other windows are tiled as usual in the background: https://hyprland-community.github.io/pyprland/layout_center.html
  "layout_center"
]

# SCRATCHPADS -----------------------------------------------------------------
[scratchpads.audio_mixer]
command = "${userSettings.term} --class scratchpad-audio-mixer -e pulsemixer"
animation = "fromRight"
class = "scratchpad-audio-mixer"
lazy = true
position = "65% 10%"
size = "30% 30%"
unfocus = "hide"

[scratchpads.calculator]
command = "${userSettings.term} --class scratchpad-calculator -e numbat --intro-banner off"
animation = "fromLeft"
class = "scratchpad-calculator"
margin = 50
lazy = true
size = "30% 80%"
unfocus = "hide"

[scratchpads.calendar]
command = "${userSettings.term} --class scratchpad-calendar -e calcure"
animation = "fromRight"
class = "scratchpad-calendar"
lazy = true
position = "45% 10%"
size = "50% 50%"
unfocus = "hide"

[scratchpads.file_manager]
command = "${userSettings.term} --class scratchpad-file-manager -e ${userSettings.fileManager}"
animation = "fromTop"
class = "scratchpad-file-manager"
lazy = true
margin = 50
size = "80% 85%"
unfocus = "hide"

[scratchpads.messaging]
command = "teams-for-linux"
animation = "fromTop"
class = "teams-for-linux"
lazy = true
margin = 50
size = "80% 85%"
unfocus = "hide"

[scratchpads.terminal]
command = "${userSettings.term} --class scratchpad-terminal"
animation = "fromTop"
class = "scratchpad-terminal"
lazy = true
margin = 50
size = "80% 85%"
unfocus = "hide"
  '';
}
