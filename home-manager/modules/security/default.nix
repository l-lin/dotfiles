#
# Security related modules.
#

{ fileExplorer, pkgs, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # Modern encryption tool with small explicit keys: https://age-encryption.org/
    age
  ];
}
