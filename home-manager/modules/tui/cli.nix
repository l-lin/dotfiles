#
# List of CLI to install that do not need special configuration.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    curl
    fd
    gcc
    lsd
    gnumake
    ripgrep
    stow
    wget
  ];
}
