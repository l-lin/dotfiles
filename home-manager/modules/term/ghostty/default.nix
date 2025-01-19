#
# 👻 Ghostty is a fast, feature-rich, and cross-platform terminal emulator that uses platform-native UI and GPU acceleration.
# src: https://ghostty.org/
#

{ config, nixgl, pkgs, ... }:
let
  palette = config.lib.stylix.colors.withHashtag;
in {
  # To access the GPU, programs need access to OpenGL and Vulkan libraries.
  # While this works transparently on NixOS, it does not on other Linux systems.
  # A solution is provided by NixGL, which can be integrated into Home Manager.
  # src: https://nix-community.github.io/home-manager/index.xhtml#sec-usage-gpu-non-nixos
  nixGL.packages = nixgl.packages;
  nixGL.defaultWrapper = "mesa";
  nixGL.offloadWrapper = "intel";

  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;

    # Use the wrapped Ghostty that uses NixGL.
    package = config.lib.nixGL.wrap pkgs.ghostty;
  };

  # Symlink ~/.config/ghostty/config
  xdg.configFile."ghostty/config".source = ./.config/ghostty/config;
  # Not using stylix because I want to use Ghostty default fonts instead.
  # I could not manage to find the same font as Ghostty...
  # Moreover, it seems the palette chosen for Ghostty is not quite right.
  xdg.configFile."ghostty/color-scheme".text = with palette; ''
#
# Color Scheme
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
