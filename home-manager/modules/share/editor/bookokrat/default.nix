#
# Terminal epub reader.
# src: https://bugzmanov.github.io/bookokrat/index.html
#

{ config, ... }:
let
  palette = config.lib.stylix.colors.withHashtag;
in {
  # bookokrat installed from brew in app.nix.

  home.file.".bookokrat_settings.yaml".text = with palette; ''
version: 1
theme: "custom"
margin: 0

custom_themes:
  - scheme: "custom"
    author: "l-lin"
    base00: "${base00-hex}"    # Main background
    base01: "${base01-hex}"    # Lighter background (status bars)
    base02: "${base02-hex}"    # Selection background
    base03: "${base05-hex}"    # Comments (black for visibility)
    base04: "${base05-hex}"    # Dark foreground (black)
    base05: "${base05-hex}"    # Default text (black)
    base06: "${base05-hex}"    # Light foreground (black)
    base07: "${base05-hex}"    # Brightest text (black)
    base08: "${base08-hex}"    # Red (errors)
    base09: "${base09-hex}"    # Orange (constants)
    base0A: "${base0A-hex}"    # Yellow (search)
    base0B: "${base0B-hex}"    # Green (strings)
    base0C: "${base0C-hex}"    # Cyan
    base0D: "${base06-hex}"    # Blue (links)
    base0E: "${base0E-hex}"    # Purple (keywords)
    base0F: "${base0F-hex}"    # Brown/Pink
  '';
}
