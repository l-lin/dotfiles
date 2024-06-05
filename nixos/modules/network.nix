{ systemSettings, ... }: {
  # Networking
  networking.hostName = systemSettings.hostname;
  networking.networkmanager.enable = true;
}
