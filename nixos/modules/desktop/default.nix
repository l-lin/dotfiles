#
# Desktop related configuration.
#

{ pkgs, systemSettings, ... }: {
  # D-Bus (short for "Desktop Bus") is a message-oriented middleware mechanism
  # that allows communication between multiple processes running concurrently on the same machine.
  services.dbus = {
    enable = true;
    packages = [ pkgs.dconf ];
  };

  # dconf is a low-level configuration system and settings management tool.
  programs.dconf.enable = true;

  # Timezone and locale
  time.timeZone = systemSettings.timezone;
  i18n = {
    defaultLocale = systemSettings.locale;
    extraLocaleSettings = {
      LC_ADDRESS = systemSettings.locale;
      LC_IDENTIFICATION = systemSettings.locale;
      LC_MEASUREMENT = systemSettings.locale;
      LC_MONETARY = systemSettings.locale;
      LC_NAME = systemSettings.locale;
      LC_NUMERIC = systemSettings.locale;
      LC_PAPER = systemSettings.locale;
      LC_TELEPHONE = systemSettings.locale;
      LC_TIME = systemSettings.locale;
    };
  };
}
