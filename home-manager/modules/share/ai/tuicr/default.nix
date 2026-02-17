#
# A human-in-the-loop code review TUI for AI-generated changes.
# src: https://github.com/agavra/tuicr
#

{ config, ... }:
let
  colorScheme = if (config.theme.polarity == "dark") then "dark" else "catppuccin-latte";
in {
  xdg.configFile = {
    "mise/conf.d/tuicr.toml".source = ./.config/mise/conf.d/tuicr.toml;
    "tuicr/config.toml".text = ''
theme = "${colorScheme}"
    '';
  };
}
