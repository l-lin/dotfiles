#
# This is your system's configuration file.
# Use this to configure your system environment.
#

{
  nix = {
    # Determinate uses its own daemon to manage the Nix installation that
    # conflicts with nix-darwin’s native Nix management.
    #
    # This will allow you to use nix-darwin with Determinate. Some nix-darwin
    # functionality that relies on managing the Nix installation, like the
    # `nix.*` options to adjust Nix settings or configure a Linux builder,
    # will be unavailable.
    enable = false;
  };

  # Allow unfree packages.
  nixpkgs.config.allowUnfree = true;

  # You can import other Nix-darwin modules here
  imports = [
    ./system.nix
    ./apps.nix
  ];
}
