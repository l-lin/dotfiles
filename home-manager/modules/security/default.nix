#
# Security related modules.
#

{ fileExplorer, pkgs, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # Simple and flexible tool for managing secrets: https://github.com/getsops/sops
    sops
  ];
}
