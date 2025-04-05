#
# Terminal emulator
# src: https://alacritty.org/
#

{
  programs.alacritty = {
    enable = true;
    settings = {
      # We do not create a symlink using `xdg.configFile.alacritty` because stylix
      # is creating the ~/.config/alacritty/alacritty.toml file. So we need to perform
      # this small "hack" to import our settings.
      import = [ ./.config/alacritty/alacritty.toml ];
    };
  };
}
