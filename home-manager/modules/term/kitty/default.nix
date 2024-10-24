#
# The fast, feature-rich, GPU based terminal emulator.
# src: https://sw.kovidgoyal.net/kitty/
#

{ outputs, systemSettings, ... }: {
  programs.kitty = {
    enable = true;
    package = outputs.packages.${systemSettings.system}.kitty;
    # https://sw.kovidgoyal.net/kitty/conf/
    settings = {
      # Bell
      visual_bell_duration = 0;
      enable_audio_bell = "no";
      bell_on_tab = "yes";

      remember_window_size = "no";

      window_padding_width = 8;

      hide_window_decorations = "yes";
    };
  };
}
