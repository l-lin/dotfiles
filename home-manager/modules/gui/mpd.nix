#
# A flexible, powerful daemon for playing music.
# src: https://www.musicpd.org/
#

{ config, pkgs, ... }: {
  services = {
    mpd = {
      enable = true;
      musicDirectory = "${config.xdg.userDirs.music}";
      dataDir = "${config.xdg.configHome}/mpd";
      extraConfig = ''
        auto_update           "yes"
        restore_paused        "yes"
        audio_output {
          type                "pulse"
          name                "Pulseaudio"
          server              "127.0.0.1" # add this line - MPD must connect to the local sound server
        }
        audio_output {
          type                "fifo"
          name                "Visualizer"
          format              "44100:16:2"
          path                "/tmp/mpd.fifo"
        }

        audio_output {
          type                "httpd"
          name                "lossless"
          encoder             "flac"
          port                "8000"
          max_client          "8"
          mixer_type          "software"
          format              "44100:16:2"
        }
      '';
      network.startWhenNeeded = true;
    };

    # Enable playerctl daemon.
    playerctld.enable = true;
  };

  home.packages = with pkgs; [
    # Command-line utility and library for controlling media players that implement MPRIS: https://github.com/acrisci/playerctl
    playerctl
  ];
}
