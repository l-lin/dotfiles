#
# Powerful CLI tool to take control of the Spotify client.
# src:
# - https://github.com/the-argus/spicetify-nix
# - https://spicetify.app/
#

{ pkgs, inputs, ... }:
let
  spicePkgs = inputs.spicetify-nix.packages.${pkgs.system}.default;
in {
  imports = [ inputs.spicetify-nix.homeManagerModule ];
  programs.spicetify = {
    enable = true;
    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";
    spotifyPackage = pkgs.spotify;

    enabledExtensions = with spicePkgs.extensions; [
      autoSkipVideo
      fullAppDisplay
      hidePodcasts
      playlistIcons
      shuffle
      trashbin
    ];
  };
}
