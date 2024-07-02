#
# ⚡️Blazing fast terminal file manager written in Rust, based on async I/O.
# src: https://yazi-rs.github.io/
#

{
  # Using `programs` instead of `home.packages` so stylix can customize the theme colors.
  programs.yazi.enable = true;

  # Symlink to ~/.config/yazi
  xdg.configFile.yazi = {
     source = ./.config/yazi;
     recursive = true;
  };
}
