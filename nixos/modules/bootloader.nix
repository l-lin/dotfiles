# Bootloader
{ systemSettings, ... }: {
  # Use systemd-boot if uefi, default to grub otherwise.
  boot.loader.systemd-boot.enable = if (systemSettings.bootMode == "uefi") then true else false;
  boot.loader.efi.canTouchEfiVariables = if (systemSettings.bootMode == "uefi") then true else false;
  # Does nothing if running bios rather than uefi.
  boot.loader.efi.efiSysMountPoint = systemSettings.bootMountPath;
  boot.loader.grub.enable = if (systemSettings.bootMode == "uefi") then false else true;
  # Does nothing if running uefi rather than bios.
  boot.loader.grub.device = systemSettings.grubDevice;
}
