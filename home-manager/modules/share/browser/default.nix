#
# Browsers to navigate the world!
#

{ userSettings, ... }: {
  imports = [
    (./. + "/${userSettings.browser}")
    ./tridactyl
  ];

  # Set the default web browser for tools like xdg-open.
  # HACK: DISABLED because I'm currently using native install of Zen browser.
  # xdg.mimeApps.defaultApplications = {
  #   "text/html" = "${userSettings.browser}.desktop";
  #   "text/xml" = "${userSettings.browser}.desktop";
  #   "x-scheme-handler/http" = "${userSettings.browser}.desktop";
  #   "x-scheme-handler/https" = "${userSettings.browser}.desktop";
  #   "x-scheme-handler/about" = "${userSettings.browser}.desktop";
  #   "x-scheme-handler/unknown" = "${userSettings.browser}.desktop";
  # };
}
