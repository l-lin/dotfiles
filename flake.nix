{
  description = "NixOS/home-manager configuration";

  inputs = {
    # Nixpkgs
    # If you need to downgrade or upgrade certains packages to address bug or compatibily issues,
    # you can use a specific nixpkgs version/hash, then use it on the specific package.
    # src: https://nixos-and-flakes.thiscute.world/nixos-with-flakes/downgrade-or-upgrade-packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # TODO: Latest bitwarden-cli is broken on master.
    nixpkgs-bitwarden-cli.url = "github:nixos/nixpkgs/c7835750e4d7bdd0ce746912ecff358b6fe7d08b";

    # Nix-darwin
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      # home-manager will use the specified version of `nixpkgs`
      # https://vtimofeenko.com/posts/practical-nix-flake-anatomy-a-guided-tour-of-flake.nix/#inputsfollows
      inputs.nixpkgs.follows = "nixpkgs";
    };
 
    # -------------------------------------------------------------

    # Hyprland window manager
    # hyprland = {
    #   url = "github:hyprwm/Hyprland";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Run unpatched binaries on NixOS
    #nix-alien.url = "github:thiagokokada/nix-alien";

    # Atomic secret provisioning for NixOS based on sops
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Spotify client
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Colorscheme management
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl.url = "github:nix-community/nixgl";

    ########################  My own repositories  #########################################

    secrets = {
      url = "git+file:./secrets";
      flake = false;
    };
  };

  outputs = {
    self,
    home-manager,
    nix-darwin,
    nixgl,
    nixpkgs,
    nixpkgs-bitwarden-cli,
    secrets,
    ...
  } @ inputs: # <- this `@inputs` will expose the block of code below, to the inputs that you set above.

  # This `let` statement allows you to set variables that you can use in the following block of code (hence the word `in`).
  # Setting variables here will allow you to pass them into your configuration.nix and home.nix files
  # you can use the variables here to create settings in multiple places within those files, but change them only one time here
  # Currently I am not using all the variables I have set, some are just place holders for the future.

  let
    inherit (self) outputs;

    # Supported systems for your flake packages, shell, etc.
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;

    lib = nixpkgs.lib;

    # ---- SYSTEM SETTINGS ---- #
    systemSettings = {
      system = "aarch64-darwin"; # system arch
      hostname = "MACM-ML2PCQ1JXG"; # hostname
      timezone = "Europe/Paris"; # select timezone
      locale = "en_US.UTF-8"; # select locale
      bootMode = "uefi"; # uefi or bios
      bootMountPath = "/boot"; # mount path for efi boot partition; only used for uefi boot mode
      grubDevice = ""; # device identifier for grub; only used for legacy (bios) boot mode
    };
    # ----- USER SETTINGS ----- #
    userSettings = {
      username = "louis.lin";
      name = "Louis LIN";
      email = "lin.louis@pm.me";

      browser = "zen"; # default browser
      fileManager = "yazi"; # TUI file manager (lf or yazi)
      editor = "nvim"; # default editor
      pager = "less"; # default pager
      term = "ghostty"; # default terminal emulator
      theme = "github-light"; # colorscheme to use
      shell = "zsh"; # shell to use
      wm = "aerospace"; # selected window manager
      wmType = "quartz"; # selected window compositor
    };

    # shared utility libraries
    fileExplorer = import ./scripts/file-explorer.nix { inherit lib; };

    specialArgs =
      inputs
      // {
        pkgs-bitwarden-cli = import nixpkgs-bitwarden-cli { system = systemSettings.system; };
        inherit fileExplorer inputs nixgl outputs secrets systemSettings userSettings;
      };
  in {
    # Your custom packages.
    # Accessible through 'nix build', 'nix shell', etc
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .'
    nixosConfigurations = {
      "${systemSettings.hostname}" = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = [./nixos/configuration.nix];
      };
    };

    # Nix-darwin configuration entrypoint.
    darwinConfigurations = {
        "${systemSettings.hostname}" = nix-darwin.lib.darwinSystem {
          inherit specialArgs;
          system = systemSettings.system;
          modules = [./nix-darwin/configuration.nix];
        };
      };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager -b backup --flake .'
    homeConfigurations = {
      "${userSettings.username}" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${systemSettings.system}; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = specialArgs;
        modules = [./home-manager/home.nix];
      };
    };
  };
}
