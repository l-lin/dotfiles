#
# Xfce file manager.
# src: https://gitlab.xfce.org/xfce/thunar
#

{ pkgs, ...}: {
  programs.thunar = {
    enable = true;

    plugins = with pkgs.xfce; [
      # Thunar plugin providing file context menus for archives
      thunar-archive-plugin
      # Thunar extension for automatic management of removable drives and media
      thunar-volman
    ];
  };

  services = {
    # Mount, trash, and other functionalities
    gvfs.enable = true;

    # Thumbnail support for images
    tumbler.enable = true;
  };
}
