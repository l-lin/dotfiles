#
# A bootloader is a type of software that manages the loading of the operating system
# (OS) on the computer at startup. It is responsible for preparing the system before
# passing control to the OS. Here are the types of bootloaders commonly used in NixOS:
#
# - GRUB (Grand Unified Bootloader): Widely used, supports multiple operating systems, and provides a boot menu to select how the system boots.
# - systemd-boot: Simple UEFI-only bootloader, formerly known as gummiboot.
# - EFISTUB: Utilizes the UEFI firmware itself to boot the kernel, without the need for a traditional bootloader.
#
# src: https://nixos.wiki/wiki/Bootloader
#

{ systemSettings, ... }: {
  boot.loader = {
    # Use systemd-boot if uefi, default to grub otherwise.
    systemd-boot.enable = if (systemSettings.bootMode == "uefi") then true else false;
    efi = {
      canTouchEfiVariables = if (systemSettings.bootMode == "uefi") then true else false;
      # Does nothing if running bios rather than uefi.
      efiSysMountPoint = systemSettings.bootMountPath;
    };

    grub = {
      enable = if (systemSettings.bootMode == "uefi") then false else true;
      # Does nothing if running uefi rather than bios.
      device = systemSettings.grubDevice;
    };
  };
}
