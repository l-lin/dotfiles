#
# 👻 Ghostty is a fast, feature-rich, and cross-platform terminal emulator that uses platform-native UI and GPU acceleration.
# src: https://ghostty.org/
#

{ config, ... }:
let
  palette = config.lib.stylix.colors.withHashtag;
in {
  #############################################################################
  # TODO: Install only on Linux.
  #
  # To access the GPU, programs need access to OpenGL and Vulkan libraries.
  # While this works transparently on NixOS, it does not on other Linux systems.
  # A solution is provided by NixGL, which can be integrated into Home Manager.
  # src: https://nix-community.github.io/home-manager/index.xhtml#sec-usage-gpu-non-nixos
  #nixGL.packages = nixgl.packages;
  #nixGL.defaultWrapper = "mesa";
  #nixGL.offloadWrapper = "intel";

  # Cannot install ghostty from home-manager. Broken package in home-manager
  # unfortunately. And it seems it will be ever possible to install ghostty from
  # home-manager for MacOs...
  # src: https://github.com/NixOS/nixpkgs/issues/388984
  #programs.ghostty = {
  #  enable = true;
  #  enableZshIntegration = true;

  #  # Use the wrapped Ghostty that uses NixGL.
  #  #package = config.lib.nixGL.wrap pkgs.ghostty;
  #};
  #############################################################################

  # Symlink ~/.config/ghostty/
  xdg.configFile."ghostty" = {
    source = ./.config/ghostty;
    recursive = true;
  };
  # Not using stylix because I want to use Ghostty default fonts instead.
  # I could not manage to find the same font as Ghostty...
  # Moreover, it seems the palette chosen for Ghostty is not quite right.
  xdg.configFile."ghostty/color-scheme".text = with palette; ''
#
# Color Scheme
#

# Theme to use. To see a list of available themes, run `ghostty +list-themes`.
# src: https://ghostty.org/docs/config/reference#theme
# Overriding the background and foreground from the one defined by Stylix
# because the colors used in the Ghostty themes are not the same as the
# color-scheme used in Neovim.
# black
palette = 0=${base00-hex}
palette = 8=${base04-hex}
# red
palette = 1=${base08-hex}
palette = 9=${base08-hex}
# green
palette = 2=${base0B-hex}
palette = 10=${base0B-hex}
# yellow
palette = 3=${base0A-hex}
palette = 11=${base0A-hex}
# blue
palette = 4=${base0D-hex}
palette = 12=${base0D-hex}
# purple
palette = 5=${base0E-hex}
palette = 13=${base0E-hex}
# aqua
palette = 6=${base0C-hex}
palette = 14=${base0C-hex}
# white
palette = 7=${base06-hex}
palette = 15=${base05-hex}
background = "${base00-hex}"
foreground = "${base05-hex}"
cursor-color = "${base05-hex}"
selection-background = "${base02-hex}"
selection-foreground = "${base05-hex}"
  '';
}
