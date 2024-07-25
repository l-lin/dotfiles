#
# Powerful CLI tool to take control of the Spotify client.
# src:
# - https://github.com/the-argus/spicetify-nix
# - https://spicetify.app/
#

{ config, inputs, pkgs, ... }:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
  theme = if (config.theme.polarity == "dark") then spicePkgs.themes.text else spicePkgs.themes.dribbblish;
  colorScheme = if (config.theme.polarity == "dark") then "kanagawa" else "catppuccin-latte";
in {
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];
  programs.spicetify = {
    enable = true;
    theme = theme;
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
      ${builtins.readFile ./scripts/spotify-play-pause.sh}
    '')
    (writeShellScriptBin "spotify-next.sh" ''
      ${builtins.readFile ./scripts/spotify-next.sh}
    '')
  ];
}
