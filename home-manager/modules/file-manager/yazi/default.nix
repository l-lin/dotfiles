#
# ⚡️Blazing fast terminal file manager written in Rust, based on async I/O.
# src: https://yazi-rs.github.io/
#

{ userSettings, ...}: {
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };

  # symlink to ~/.config/yazi
  xdg.configFile."yazi/keymap.toml".source = ./config/keymap.toml;
  xdg.configFile."yazi/yazi.toml".source = ./config/yazi.toml;
}
