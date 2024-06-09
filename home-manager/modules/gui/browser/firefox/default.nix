#
# Web browser.
#

{ pkgs, ... }: {
  programs.firefox = {
    enable = true;
  };

  imports = [ ./tridactyl ];
}
