#
# List of CLI to install that do not need special configuration.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    curl
    fd
    fzf
    gcc
    lsd
    gnumake
    ripgrep

    # Enhanced SPICE integration for linux QEMU guest
    # Spice agent for linux guests offering
    # - Client mouse mode
    # - Copy and paste
    # - Automatic adjustment of the X-session resolution to the client resolution
    # - Multiple displays
    #spice-vdagent

    stow
    wget
  ];
}
