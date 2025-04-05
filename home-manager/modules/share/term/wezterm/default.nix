#
# WezTerm is a powerful cross-platform terminal emulator and multiplexer.
# src: https://wezfurlong.org/wezterm/index.html
#
# TODO: List of missing features not configured / fixed yet:
# - [ ] support displaying images with `yazi` and `presenterm` (wezterm is throwing a font error instead...)
# - [ ] better full screen support (WezTerm adds some weird padding / black lines at top and bottom)
# - [ ] change cursor color when window not focused (currently set to green by default)
# - [ ] sometime, there's an error `ERROR  window::os::wayland::window > hide_cursor: Missing enter event serial` in the logs.`
#

{ config, nixgl, pkgs, ... }: {
  # To access the GPU, programs need access to OpenGL and Vulkan libraries.
  # While this works transparently on NixOS, it does not on other Linux systems.
  # A solution is provided by NixGL, which can be integrated into Home Manager.
  # src: https://nix-community.github.io/home-manager/index.xhtml#sec-usage-gpu-non-nixos
  nixGL.packages = nixgl.packages;
  nixGL.defaultWrapper = "mesa";
  nixGL.offloadWrapper = "intel";

  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;

    package = config.lib.nixGL.wrap pkgs.wezterm;

    extraConfig =  builtins.readFile ./.config/wezterm/custom.lua;
  };
}
