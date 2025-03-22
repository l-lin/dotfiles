#
# A flexible, powerful daemon for playing music.
# src: https://www.musicpd.org/
#

{ config, pkgs, ... }: {
  home.packages = with pkgs; [ mpd ];

  # Default config available here: https://raw.githubusercontent.com/MusicPlayerDaemon/MPD/master/doc/mpdconf.example
  xdg.configFile."mpd/mpd.conf".text = ''
# Recommended location for database
db_file         "${config.xdg.dataHome}/mpd/database"

# If running mpd using systemd, delete this line to log directly to systemd.
log_file        "${config.xdg.dataHome}/mpd/mpd.log"

# This setting sets the location of the file which stores the process ID
# for use of mpd --kill and some init scripts. This setting is disabled by
# default and the pid file will not be stored.
pid_file        "${config.xdg.dataHome}/mpd/mpd.pid"

# The music directory is by default the XDG directory, uncomment to amend and choose a different directory
music_directory "${config.xdg.userDirs.music}"

# Put MPD into pause mode instead of starting playback after startup.
restore_paused  "yes"

# This specifies the whether to support automatic update of music database when files are changed in music_directory. The default is to disable autoupdate of database.
auto_update     "yes"

# Make it work with PipeWire.
# src: https://nixos.wiki/wiki/MPD#PipeWire
# audio_output {
#   type "pipewire"
#   name "PipeWire"
# }

# Make it work with PulseAudio.
audio_output {
  type "pulse"
  name "PulseAudio"
}

# Useful to visualize MPD output with a MPD client, e.g. ncmpcpp.
audio_output {
  type    "fifo"
  name    "Visualizer"
  format  "44100:16:2"
  path    "/tmp/mpd.fifo"
}
  '';
}
