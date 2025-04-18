#
# Replacement for a shell history which records additional commands
# context with optional encrypted synchronization between machines.
# src: https://github.com/atuinsh/atuin
#

{ config, pkgs, secrets, ... }:
let
  palette = config.lib.stylix.colors.withHashtag;
in {
  home.packages = with pkgs; [ atuin ];

  # Generate the atuin key with sops-nix.
  sops.secrets.atuin-key.sopsFile = "${secrets}/sops/api-keys.yaml";

  # Symlink to ~/.config/atuin/config.toml
  xdg.configFile."atuin/config.toml".text = ''
## where to store your encryption key, default is your system data directory
key_path = "${config.sops.secrets.atuin-key.path}"

## enable or disable showing a preview of the selected command
## useful when the command is longer than the terminal width and is cut off
show_preview = true

## Configure the maximum height of the preview to show.
## Useful when you have long scripts in your history that you want to distinguish
## by more than the first few lines.
max_preview_height = 5

## Configure whether or not to show the help row, which includes the current Atuin
## version (and whether an update is available), a keymap hint, and the total
## amount of commands in your history.
show_help = true

## Defaults to true. If enabled, upon hitting enter Atuin will immediately execute the command. Press tab to return to the shell and edit.
# This applies for new installs. Old installs will keep the old behaviour unless configured otherwise.
enter_accept = true

## Defaults to "emacs".  This specifies the keymap on the startup of `atuin
## search`.  If this is set to "auto", the startup keymap mode in the Atuin
## search is automatically selected based on the shell's keymap where the
## keybinding is defined.  If this is set to "emacs", "vim-insert", or
## "vim-normal", the startup keymap mode in the Atuin search is forced to be
## the specified one.
keymap_mode = "auto"

## Cursor style in each keymap mode.  If specified, the cursor style is changed
## in entering the cursor shape.  Available values are "default" and
## "{blink,steady}-{block,underilne,bar}".
keymap_cursor = { emacs = "blink-block", vim_insert = "blink-bar", vim_normal = "steady-block" }

## Invert the UI - put the search bar at the top.
#invert = true

## Enable this, and Atuin will reduce motion in the TUI as much as possible.
## Users with motion sensitivity can find the live-updating timestamps distracting.
prefers_reduced_motion = true

## The history filter allows you to exclude commands from history tracking.
history_filter = [
  "^ddgr",
  "^export "
]

[theme]
name = "custom"
  '';
  xdg.configFile."atuin/themes/custom.toml".text = with palette; ''
[theme]
name = "custom"

[colors]
AlertInfo = "${base0D-hex}"
AlertWarn = "${base0A-hex}"
AlertError = "${base08-hex}"
Annotation = "${base07-hex}"
Base = "${base05-hex}"
Guidance = "${base0C-hex}"
Important = "${base0E-hex}"
Title = "${base0D-hex}"
  '';

  # Symlink ~/.config/zsh/plugins/atuin
  xdg.configFile."zsh/plugins/atuin" = {
    source = ./.config/zsh/plugins/atuin;
    recursive = true;
  };
}

