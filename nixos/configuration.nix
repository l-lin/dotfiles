#
# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
#

{ inputs, lib, config, pkgs, userSettings, ... }: {
  # You can import other NixOS modules here
  imports = [
    # Import your generated (nixos-generate-config) hardware configuration
    # Auto-generated in /etc/nixos/ folder or by executing the following command:
    # nixos-generate-config --show-hardware-config
    ./hardware-configuration.nix

    # System stuff
    ./modules/audio.nix
    ./modules/bootloader.nix
    ./modules/dbus.nix
    ./modules/i18n-l10n.nix
    ./modules/network.nix
    ./modules/pipewire.nix
    ./modules/printing.nix
    ./modules/ssh
    ./modules/users.nix
    #./modules/vm.nix

    # UI
    ./modules/gui
    ./modules/tui
  ];

  # Nixpkgs stuff
  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  # NOTE: I have no idea what the following does.
  # Copied from https://github.com/Misterio77/nix-starter-configs/blob/main/minimal/nixos/configuration.nix#L43-L60.
  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry
      flake-registry = "";
      # Workaround for https://github.com/NixOS/nix/issues/9574
      nix-path = config.nix.nixPath;
    };
    # Enable automatic garbage collection.
    # src: https://nixos.wiki/wiki/Storage_optimization
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    # Automatically run the nix store optimiser at a specific time (default to 03:45, set by `nix.optimise.dates`).
    optimise.automatic = true;

    # Opinionated: disable channels
    channel.enable = false;

    # Opinionated: make flake registry and nix path match flake inputs
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  # System packages
  environment.systemPackages = with pkgs; [ home-manager ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
