#
# 👻 Ghostty is a fast, feature-rich, and cross-platform terminal emulator that uses platform-native UI and GPU acceleration.
# src: https://ghostty.org/
#

{ config, nixgl, pkgs, ... }: {
  #
  # To access the GPU, programs need access to OpenGL and Vulkan libraries.
  # While this works transparently on NixOS, it does not on other Linux systems.
  # A solution is provided by NixGL, which can be integrated into Home Manager.
  # src: https://nix-community.github.io/home-manager/index.xhtml#sec-usage-gpu-non-nixos
  nixGL.packages = nixgl.packages;
  nixGL.defaultWrapper = "mesa";
  nixGL.offloadWrapper = "intel";

  # Cannot install ghostty from home-manager. Broken package in home-manager
  # unfortunately. And it seems it will be ever possible to install ghostty from
  # home-manager for MacOs...
  # src: https://github.com/NixOS/nixpkgs/issues/388984
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;

    # Use the wrapped Ghostty that uses NixGL.
    package = config.lib.nixGL.wrap pkgs.ghostty;
  };
}
