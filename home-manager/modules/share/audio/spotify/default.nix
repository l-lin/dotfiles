#
# Powerful CLI tool to take control of the Spotify client.
# src:
# - https://github.com/the-argus/spicetify-nix
# - https://spicetify.app/
#

{ config, inputs, pkgs, ... }:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
  colorScheme = if (config.theme.polarity == "dark") then "catppuccin-mocha" else "catppuccin-latte";
in {
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];
  programs.spicetify = {
    enable = true;
    theme = spicePkgs.themes.dribbblish;
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
    (writeShellScriptBin "spotify-toggle" ''
      ${builtins.readFile ./scripts/spotify-toggle.sh}
    '')
    (writeShellScriptBin "spotify-next" ''
      ${builtins.readFile ./scripts/spotify-next.sh}
    '')
  ];
}
