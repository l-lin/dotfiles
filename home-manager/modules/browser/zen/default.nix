#
# 🌀 Experience tranquillity while browsing the web without people tracking you!
# src: https://zen-browser.app/
#

{ inputs, pkgs, ... }:
let
  zenPkgs = inputs.zen-browser.packages.${pkgs.system};
in {
  home.packages = [ zenPkgs.specific ];
}
