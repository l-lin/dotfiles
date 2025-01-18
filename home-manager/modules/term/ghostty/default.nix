#
# 👻 Ghostty is a fast, feature-rich, and cross-platform terminal emulator that uses platform-native UI and GPU acceleration.
# src: https://ghostty.org/
#

{ config, ... }:
let
  palette = config.lib.stylix.colors.withHashtag;
in {
  # HACK: DISABLED because Ghostty is not working well on Ubuntu with
  # home-manager, as it crashes on startup with the following error:
  # > Failed to create EGL display
  # The solution to use NixGL does not work for me, as I'm getting another error:
  # > error(gtk_surface): surface failed to realize: error.CannotOpenResource
  # src: https://github.com/ghostty-org/ghostty/discussions/3763
  # So the last way is to install via the `.deb` file...
  # src: https://ghostty.org/docs/install/binary#ubuntu
  #home.packages = with pkgs; [ ghostty ];

  # Symlink ~/.config/ghostty/config
  xdg.configFile."ghostty/config".source = ./.config/ghostty/config;
  xdg.configFile."ghostty/color-scheme".text = with palette; ''
#
# UI
#

# Theme to use. To see a list of available themes, run `ghostty +list-themes`.
# src: https://ghostty.org/docs/config/reference#theme
theme = "${config.theme.ghosttyColorScheme}"
# Overriding the background and foreground from the one defined by Stylix
# because the colors used in the Ghostty themes are not the same as the
# color-scheme used in Neovim.
background = "${base00-hex}"
foreground = "${base05-hex}"
  '';
}
