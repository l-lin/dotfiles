#
# Web browser.
#

{
  programs.firefox = {
    enable = true;
  };

  imports = [ ./tridactyl ];
}
