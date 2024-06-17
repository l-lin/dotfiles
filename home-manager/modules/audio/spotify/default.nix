#
# Powerful CLI tool to take control of the Spotify client.
# src:
# - https://github.com/the-argus/spicetify-nix
# - https://spicetify.app/
#

{ config, inputs, pkgs, ... }:
let
  spicePkgs = inputs.spicetify-nix.packages.${pkgs.system}.default;
  colorScheme = if (config.theme.polarity == "dark") then "mocha" else "latte";
in {
  imports = [ inputs.spicetify-nix.homeManagerModule ];
  programs.spicetify = {
    enable = true;
    theme = spicePkgs.themes.catppuccin;
    colorScheme = colorScheme;
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

  home.packages = with pkgs; [
    (writeShellScriptBin "spotify-play-pause.sh" ''
      ${builtins.readFile ./script/spotify-play-pause.sh}
    '')
    (writeShellScriptBin "spotify-next.sh" ''
      ${builtins.readFile ./script/spotify-next.sh}
    '')
  ];
}
