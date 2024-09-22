#
# Browsers to navigate the world!
#

{ userSettings, ... }: {
  imports = [
    (./. + "/${userSettings.browser}")
    ./tridactyl
    #./zen
  ];

  # Set the default web browser for tools like xdg-open.
  xdg.mimeApps.defaultApplications = {
    "text/html" = "${userSettings.browser}.desktop";
    "text/xml" = "${userSettings.browser}.desktop";
    "x-scheme-handler/http" = "${userSettings.browser}.desktop";
    "x-scheme-handler/https" = "${userSettings.browser}.desktop";
    "x-scheme-handler/about" = "${userSettings.browser}.desktop";
    "x-scheme-handler/unknown" = "${userSettings.browser}.desktop";
  };
}
