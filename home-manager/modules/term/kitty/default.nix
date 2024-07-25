#
# The fast, feature-rich, GPU based terminal emulator.
# src: https://sw.kovidgoyal.net/kitty/
#

{
  programs.kitty = {
    enable = true;
    # https://sw.kovidgoyal.net/kitty/conf/
    settings = {
      # Bell
      visual_bell_duration = 0;
      enable_audio_bell = "no";
      bell_on_tab = "yes";

      window_padding_width = 12;
    };
    keybindings = {
      "ctrl+shift+t" = "none";
    };
  };
}
