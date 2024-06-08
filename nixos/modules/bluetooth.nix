#
# Bluetooth configuration.
# src: https://nixos.wiki/wiki/Bluetooth
#

{
  # Enables support for Bluetooth
  hardware.bluetooth.enable = true;
  # Powers up the default Bluetooth controller on boot
  hardware.bluetooth.powerOnBoot = true;
  # Bluetooth manager: https://github.com/blueman-project/blueman
  services.blueman.enable = true;
}
