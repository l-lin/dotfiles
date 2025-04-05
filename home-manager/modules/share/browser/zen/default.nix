#
# 🌀 Experience tranquillity while browsing the web without people tracking you!
# Zen mod to install:
# - [no gap](https://zen-browser.app/mods/bfcc400a-4ecb-4752-bfd2-a68f116a2722/)
# src: https://zen-browser.app/
#

{}

# TODO: Using the native installation. I should revert to use the one installed by home-manager
# once https://github.com/NixOS/nixpkgs/pull/347222 is merged.
# However, WebGL won't work...
# { inputs, pkgs, ... }:
# let
#   zenPkgs = inputs.zen-browser.packages.${pkgs.system};
# in {
#   # Installing zen directly from their store, because WebGL is not supported by browsers installed via Nix :(
#   home.packages = [ zenPkgs.specific ];
# }
