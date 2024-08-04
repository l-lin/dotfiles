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
position = "49% 10%"
size = "50% 50%"
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
command = "${userSettings.term} --class scratchpad-calendar -e ${userSettings.shell} -c 'cal -n 2 -m --color=always | less'"
animation = "fromRight"
class = "scratchpad-calendar"
lazy = true
position = "74% 10%"
size = "25% 25%"
unfocus = "hide"

[scratchpads.file_manager]
command = "${userSettings.term} --class scratchpad-file-manager -e ${userSettings.fileManager}"
animation = "fromTop"
class = "scratchpad-file-manager"
lazy = true
margin = 50
size = "80% 85%"
unfocus = "hide"

[scratchpads.spotify]
command = "spotify"
animation = "fromBottom"
title = "re:.*Spotify.*"
match_by = "title"
lazy = true
margin = 50
unfocus = "hide"

[scratchpads.music_player]
command = "${userSettings.term} --class scratchpad-music-player -e ncmpcpp --screen visualizer"
animation = "fromRight"
class = "scratchpad-music-player"
lazy = true
position = "74% 69%"
size = "25% 25%"

[scratchpads.messaging]
command = "slack"
animation = "fromBottom"
class = "Slack"
lazy = true
margin = 10
size = "90% 90%"
unfocus = "hide"

# LAYOUT_CENTER -----------------------------------------------------------------

[layout_center]
margin = 32
next = "movefocus d"
prev = "movefocus u"
next2 = "movefocus r"
prev2 = "movefocus l"
  '';
}
