{
  description = "l-lin NixOS/home-manager configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland window manager
    hyprland = {
      url = "github:hyprwm/Hyprland/v0.40.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Colorscheme
    nix-colors.url = "github:misterio77/nix-colors";

    lf-icons = {
      url = "github:gokcehan/lf";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    nix-colors,
    home-manager,
    ...
  } @ inputs: # <- this `@inputs` will expose the block of code below, to the inputs that you set above.

  # This `let` statement allows you to set variables that you can use in the following block of code (hence the word `in`).
  # Setting variables here will allow you to pass them into your configuration.nix and home.nix files
  # you can use the variables here to create settings in multiple places within those files, but change them only one time here
  # Currently I am not using all the variables I have set, some are just place holders for the future.

  let
    inherit (self) outputs;

    # ---- SYSTEM SETTINGS ---- #
    systemSettings = {
      system = "x86_64-linux"; # system arch
      hostname = "nixos"; # hostname
      timezone = "Europe/Paris"; # select timezone
      locale = "en_US.UTF-8"; # select locale
      bootMode = "uefi"; # uefi or bios
      bootMountPath = "/boot"; # mount path for efi boot partition; only used for uefi boot mode
      grubDevice = ""; # device identifier for grub; only used for legacy (bios) boot mode
    };
    # ----- USER SETTINGS ----- #
    userSettings = {
      username = "l-lin";
      name = "Louis LIN";
      editor = "nvim"; # default editor
      term = "alacritty"; # default terminal emulator
      colorscheme = "kanagawa"; # colorscheme to use
      shell = "zsh"; # shell to use
      wm = "hyprland"; # selected window manager (hyprland, sway or gnome)
      wmType = "wayland"; # selected window manager type (wayland or x11)
      browser = "firefox"; # default browser
    };

  in {
    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .'
    nixosConfigurations = {
      "${systemSettings.hostname}" = nixpkgs.lib.nixosSystem {
        specialArgs = {
          # pass config variables from above
          inherit systemSettings;
          inherit userSettings;
          inherit inputs outputs;
        };
        modules = [./nixos/configuration.nix];
      };
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager -b backup --flake .'
    homeConfigurations = {
      "${userSettings.username}" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${systemSettings.system}; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {
          # pass config variables from above
          inherit userSettings;
          inherit nix-colors;
          inherit inputs outputs;
        };
        modules = [./home-manager/home.nix];
      };
    };
  };
}
