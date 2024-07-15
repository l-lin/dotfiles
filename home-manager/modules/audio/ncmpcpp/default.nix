#
# A featureful ncurses based MPD client inspired by ncmpc.
# src: https://rybczak.net/ncmpcpp/
#

{ config, pkgs, userSettings, ...}: let
  ncmpcpp = pkgs.ncmpcpp.override { visualizerSupport = true; };
in {
  home.packages = [ ncmpcpp ];

  # Symlinks to ~/.config/ncmpcpp.
  xdg.configFile."ncmpcpp/bindings".source = ./.config/ncmpcpp/bindings;
  # Default configuration: https://github.com/ncmpcpp/ncmpcpp/blob/master/doc/config.
  xdg.configFile."ncmpcpp/config".text = ''
# miscelaneous
ncmpcpp_directory = ${config.xdg.configHome}/ncmpcpp
external_editor = ${userSettings.editor}

# visualizer
visualizer_data_source = /tmp/mpd.fifo
visualizer_output_name = mpd_visualizer
visualizer_type = spectrum
visualizer_look = ●●
visualizer_color = blue, cyan, green, yellow, magenta, red
visualizer_in_stereo = no

# appearance
colors_enabled = yes
playlist_display_mode = classic
user_interface = classic

# window
song_window_title_format = Music
statusbar_visibility = no
header_visibility = no
titles_visibility = no

# progress bar
progressbar_look = ▃▃▃
# in light theme, black is white!
progressbar_color = black
progressbar_elapsed_color = blue
    '';
}
