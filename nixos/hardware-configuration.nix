# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/28a49b64-6b2a-4079-b749-cc811c15197a";
      fsType = "ext4";
    };

  boot.initrd.luks.devices."luks-4bf10a93-6a54-44fc-b9f4-9f7d22aa80be".device = "/dev/disk/by-uuid/4bf10a93-6a54-44fc-b9f4-9f7d22aa80be";

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/2B59-406B";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/9a05af13-67d3-433a-8d7b-7efde3e0dca9"; }
    ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.br-315d482c477e.useDHCP = lib.mkDefault true;
  # networking.interfaces.docker0.useDHCP = lib.mkDefault true;
  # networking.interfaces.veth004ff74.useDHCP = lib.mkDefault true;
  # networking.interfaces.vethd8f804c.useDHCP = lib.mkDefault true;
  # networking.interfaces.vethdb273f4.useDHCP = lib.mkDefault true;
  # networking.interfaces.vethe2668ba.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlo1.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
