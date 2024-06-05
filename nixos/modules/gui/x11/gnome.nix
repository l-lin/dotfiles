{ userSettings, ... }: {
  services.xserver = {
    enable = true;

    # Enable the GNOME Desktop Environment.
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    # Configure keymap in X11.
    # Exhaustive list of options: https://mynixos.com/nixpkgs/options/services.xserver.xkb
    xkb = {
      layout = "us";
      variant = "altgr-intl";
      # Not working... I had to install gnome-tweaks to manually change it.
      options = "ctrl:nocaps";
    };
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin = {
    enable = true;
    user = userSettings.username;
  };

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
}
