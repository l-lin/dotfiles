#
# Dynamic tiling Wayland compositor
# See:
# - https://hyprland.org/
# - https://nixos.wiki/wiki/Hyprland
# - https://wiki.hyprland.org/Nix/Hyprland-on-NixOS/
#

{ config, fileExplorer, pkgs, userSettings, ... }:
let
  palette = config.lib.stylix.colors;
in {
  imports = fileExplorer.allSubdirs ./.;

  wayland.windowManager.hyprland = {
    # Whether to enable Hyprland wayland compositor
    enable = true;
    # The hyprland package to use
    package = pkgs.hyprland;
    extraConfig = ''
########################################### VARIABLES #######################################
# https://wiki.hyprland.org/Configuring/Keywords/

$main_mod = SUPER

$audio_mixer = pypr toggle audio_mixer
$browser = ${userSettings.browser}
$calendar = pypr toggle calendar
$calculator = pypr toggle calculator
$color_picker = hyprpicker -a -r
$file_manager = pypr toggle file_manager
$lock_screen = hyprlock
$logout = wlogout
$menu = rofi -show drun
$messaging = pypr toggle messaging
$music_player = pypr toggle music_player
$screenshot = grim -g "$(slurp)" - | satty --filename - --fullscreen --output-filename ${config.xdg.userDirs.pictures}/screenshot-$(date '+%Y-%m-%d-%H%M%S').png --copy-command wl-copy --early-exit
$screenrecord = pkill wf-recorder || wf-recorder -g "$(slurp)" -f ${config.xdg.userDirs.videos}/screenrecord-$(date '+%Y-%m-%d-%H%M%S').mp4
$terminal = ${userSettings.term} -e tmux -2 -u
$terminal_float = pypr toggle terminal

# color scheme
$active_border_color = rgb(${palette.base05})
$inactive_border_color = rgb(${palette.base00})

$monitor0 = eDP-1
$monitor1 = DP-1

${builtins.readFile ./.config/hypr/hyprland.conf}
    '';
  };
}
