#
# Something you want to use that's not in nixpkgs yet? You can easily
# build and iterate on a derivation (package) from this very repository.
#
# Create a folder with the desired name inside pkgs. Be sure to also callPackage
# them on this file.
#
# You'll be able to refer to that package from anywhere on your home-manager/nixos
# configurations, build them with `nix build '.#package-name'`, or bring them into
# your shell with `nix shell '.#package-name'`.
#

pkgs: {
  openfortivpn-webview = pkgs.callPackage ./openfortivpn-webview { };
  kitty = pkgs.callPackage ./kitty { };
}
