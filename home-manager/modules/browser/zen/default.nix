#
# 🌀 Experience tranquillity while browsing the web without people tracking you!
# src: https://zen-browser.app/
#

{}
# { inputs, pkgs, ... }:
# let
#   zenPkgs = inputs.zen-browser.packages.${pkgs.system};
# in {
#   # Installing zen directly from their store, because WebGL is not supported by browsers installed via Nix :(
#   home.packages = [ zenPkgs.specific ];
# }
