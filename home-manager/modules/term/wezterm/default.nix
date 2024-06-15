#
# WezTerm is a powerful cross-platform terminal emulator and multiplexer.
# src: https://wezfurlong.org/wezterm/index.html
#
# /!\ not working, terminal is not starting :(
#

{
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
  };
}
