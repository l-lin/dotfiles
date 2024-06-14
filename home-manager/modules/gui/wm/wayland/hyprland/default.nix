#
# Dynamic tiling Wayland compositor
# See:
# - https://hyprland.org/
# - https://nixos.wiki/wiki/Hyprland
# - https://wiki.hyprland.org/Nix/Hyprland-on-NixOS/
#

{ config, pkgs, userSettings, ... }:
let
  palette = config.colorScheme.palette;
in {
  wayland.windowManager.hyprland = {
    # Whether to enable Hyprland wayland compositor
    enable = true;
    # The hyprland package to use
    package = pkgs.hyprland;
    extraConfig = ''
      # Documentation: https://wiki.hyprland.org/Configuring/Configuring-Hyprland/
      #
      # Default values: https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.conf
      #
      # Some examples:
      # - https://github.com/hyper-dot/Arch-Hyprland/blob/main/.config/hypr/window_rules.conf
      # - https://github.com/chadcat7/crystal/blob/main/home/namish/conf/ui/hyprland/default.nix
      # - https://github.com/notusknot/dotfiles-nix/blob/main/modules/hyprland/hyprland.conf
      # - https://gitlab.com/librephoenix/nixos-config/-/blob/main/user/wm/hyprland/hyprland.nix
      # - https://gitlab.com/hmajid2301/dotfiles/-/tree/main/modules/home/desktops/hyprland

      ########################################### VARIABLES #######################################
      # https://wiki.hyprland.org/Configuring/Keywords/

      $main_mod = SUPER
      $terminal = ${userSettings.term}
      $file_manager = ${userSettings.term} --class floating --command ${userSettings.fileManager}
      $menu = rofi -show drun
      $color_picker = hyprpicker -a -r
      $lock_screen = swaylock
      $screenshot = grim -g "$(slurp)" - | satty --filename - --fullscreen --output-filename ${config.xdg.userDirs.pictures}/screenshot-$(date '+%Y-%m-%d-%H%M%S').png --copy-command wl-copy --early-exit
      $audio_mixer = ${userSettings.term} --class floating --command pulsemixer
      $browser = ${userSettings.browser}
      $calendar = ${userSettings.term} --class floating --command calcure

      $monitor0 = eDP-1
      $monitor1 = DP-1

      ########################################### ENV VARIABLES #######################################
      # https://wiki.hyprland.org/Configuring/Environment-variables/

      # Hint electron apps to use wayland: https://nixos.wiki/wiki/Wayland#Electron_and_Chromium
      # More about Ozone Wayland: https://blogs.igalia.com/msisov/2020/11/20/chrome-chromium-on-wayland-the-waylandification-project/
      env = NIXOS_OZONE_WL, 1

      ########################################### AUTOSTART #######################################
      # Autostart necessary processes (like notifications daemons, status bars, etc.)

      exec-once = swaybg -i ${config.xdg.userDirs.pictures}/summer-dark.png -m center
      exec-once = waybar
      exec-once = dunst

      # Set screen color temperature
      exec-once = wlsunset -t 4000 -T 4500

      # Open default applications
      exec-once = [workspace 1 silent] obsidian
      exec-once = [workspace 2 silent] $terminal
      exec-once = [workspace 3 silent] $browser

      # Set cursor: https://wiki.hyprland.org/FAQ/#how-do-i-change-me-mouse-cursor
      # TODO: use theme variable to set it
      exec-once = hyprctl setcursor Qogir 24

      ########################################### DEVICES #######################################

      # https://wiki.hyprland.org/Configuring/Monitors/
      # List all monitors with `hyprctl monitors all`.
      # Syntax: monitor=name, resolution, position, scale
      monitor = $monitor0, 1920x1080@60, 0x0, 1
      monitor = $monitor1, 1920x1080@60, 1920x0, 1
      #monitor = ,preferred,auto,auto

      # Mouse and keyboard
      # https://wiki.hyprland.org/Configuring/Variables/#input
      input {
        kb_layout = us
        kb_variant = altgr-intl
        kb_model =
        kb_options = ctrl:nocaps
        kb_rules =

        # Specify if and how cursor movement should affect window focus.
        # 0 - Cursor movement will not change focus.
        # 1 - Cursor movement will always change focus to the window under the cursor.
        # 2 - Cursor focus will be detached from keyboard focus. Clicking on a window will move keyboard focus to that window.
        # 3 - Cursor focus will be completely separate from keyboard focus. Clicking on a window will not change keyboard focus.
        follow_mouse = 1
        # If enabled (1 or 2), focus will change to the window under the cursor when changing from
        # tiled-to-floating and vice versa. If 2, focus will also follow mouse on float-to-float switches.
        float_switch_override_focus = 2
        numlock_by_default = true

        touchpad {
          # Inverts scrolling direction. When enabled, scrolling moves content directly, rather than manipulating a scrollbar.
          natural_scroll = yes
        }
      }

      # Touchpad
      # https://wiki.hyprland.org/Configuring/Variables/#gestures
      gestures {
        workspace_swipe = true
        workspace_swipe_fingers = 3
        workspace_swipe_distance = 250
        workspace_swipe_invert = true
        workspace_swipe_min_speed_to_force = 15
        workspace_swipe_cancel_ratio = 0.5
        workspace_swipe_create_new = true
      }

      ########################################### LOOK AND FEEL #######################################
      # See: https://wiki.hyprland.org/Configuring/Variables/

      # https://wiki.hyprland.org/Configuring/Variables/#general
      general {
        # Gaps between windows
        gaps_in = 8
        # gaps between windows and monitor edges
        gaps_out = 14
        border_size = 2

        # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
        col.active_border = rgb(${palette.base0D})
        col.inactive_border = rgb(${palette.base00})

        # Set to true enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true

        # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
        allow_tearing = false

        # Disable borders for floating windows
        no_border_on_floating = false

        # Which layout to use (dwindle or master)
        layout = dwindle

        # After how many seconds of cursor's inactivity to hide it.
        cursor_inactive_timeout = 5
      }

      # https://wiki.hyprland.org/Configuring/Variables/#decoration
      decoration {
        # Rounded corners' radius
        rounding = 8

        # Change transparency of focused and unfocused windows
        active_opacity = 1.0
        inactive_opacity = 0.8
        fullscreen_opacity = 1.0

        # https://wiki.hyprland.org/Configuring/Performance/#how-do-i-make-hyprland-draw-as-little-power-as-possible-on-my-laptop
        # Enable drop shadows on windows
        drop_shadow = false
        # Shadow range (“size”) in layout px
        shadow_range = 60
        col.shadow = rgba(1a1a1aee)

        # https://wiki.hyprland.org/Configuring/Variables/#blur
        blur {
          enabled = false
        }
      }

      # - https://wiki.hyprland.org/Configuring/Variables/#animations
      # - https://wiki.hyprland.org/Configuring/Animations/
      animations {
        enabled = true

        bezier = myBezier, 0.05, 0.9, 0.1, 1.05

        animation = windows, 1, 7, myBezier
        animation = windowsOut, 1, 7, default, popin 80%
        animation = border, 1, 10, default
        animation = borderangle, 1, 8, default
        animation = fade, 1, 7, default
        animation = workspaces, 1, 6, default
      }

      # Dwindle is a BSPWM-like layout, where every window on a workspace is a member of a binary tree.
      # https://wiki.hyprland.org/Configuring/Dwindle-Layout/
      dwindle {
        # Pseudotiled windows retain their floating size when tiled.
        pseudotile = true
        # If enabled, the split (side/top) will not change regardless of what happens to the container.
        preserve_split = true
      }

      # https://wiki.hyprland.org/Configuring/Master-Layout/
      master {
        # Whether a newly open window should replace the master or join the slaves.
        new_is_master = true
      }

      # https://wiki.hyprland.org/Configuring/Variables/#misc
      misc {
        # Set to 0 or 1 to disable the anime mascot wallpapers
        force_default_wallpaper = 0
        # If true disables the random hyprland logo / anime girl background. :(
        disable_hyprland_logo = true

        # If true, the config will not reload automatically on save, and instead
        # needs to be reloaded with hyprctl reload. Might save on battery.
        disable_autoreload = true

        # Will make mouse focus follow the mouse when drag and dropping.
        always_follow_on_dnd = true
        # If true, will make keyboard-interactive layers keep their focus on mouse move (e.g. wofi, bemenu)
        layers_hog_keyboard_focus = true
        # If true, will animate manual window resizes/moves
        animate_manual_resizes = false
        # Whether Hyprland should focus an app that requests to be focused (an activate request)
        focus_on_activate = true

        # https://wiki.hyprland.org/Configuring/Performance/#how-do-i-make-hyprland-draw-as-little-power-as-possible-on-my-laptop
        # Controls the VFR status of Hyprland.
        vfr = true
      }

      ########################################### WINDOWS #######################################
      # https://wiki.hyprland.org/Configuring/Window-Rules/

      windowrulev2 = suppressevent maximize, class:.*
      windowrulev2 = float, class:floating
      windowrulev2 = size 950 600, class:floating

      ########################################### WORKSPACES #######################################
      # https://wiki.hyprland.org/Configuring/Workspace-Rules/

      # Bind workspace 1 to monitor 0, and so on
      # Workspace index starts from 1.
      workspace = 1, persistent:true, monitor:$monitor0, default:true
      workspace = 2, persistent:true, monitor:$monitor1, default:true
      workspace = 3, persistent:true, monitor:$monitor1, default:true
      workspace = 4, persistent:true, monitor:$monitor1, default:true
      workspace = 5, persistent:true, monitor:$monitor1, default:true

      ########################################### KEYBINDINGS #######################################
      # https://wiki.hyprland.org/Configuring/Binds/

      bind = $main_mod, Return ,exec, $terminal
      bind = $main_mod, Q, killactive,
      bind = $main_mod, M, exec, $lock_screen
      bind = $main_mod, E, exec, $file_manager
      bind = $main_mod, V, togglefloating,
      bind = $main_mod, F, fullscreen, 0
      bind = $main_mod, SPACE, exec, $menu
      bind = $main_mod, P, exec, $color_picker
      bind = $main_mod, I, togglesplit
      bind = $main_mod, S, exec, $screenshot
      bind = $main_mod, A, exec, $audio_mixer
      bind = $main_mod, C, exec, $calendar

      # Move focus with main_mod + hjkl
      bind = $main_mod, h, movefocus, l
      bind = $main_mod, l, movefocus, r
      bind = $main_mod, k, movefocus, u
      bind = $main_mod, j, movefocus, d

      # Move window in current workspace
      bind = $main_mod SHIFT, h, movewindow, l
      bind = $main_mod SHIFT, l, movewindow, r
      bind = $main_mod SHIFT, k, movewindow, u
      bind = $main_mod SHIFT, j, movewindow, d

      # Switch workspaces with main_mod + [0-9]
      bind = $main_mod, 1, workspace, 1
      bind = $main_mod, 2, workspace, 2
      bind = $main_mod, 3, workspace, 3
      bind = $main_mod, 4, workspace, 4
      bind = $main_mod, 5, workspace, 5
      bind = $main_mod, 6, workspace, 6
      bind = $main_mod, 7, workspace, 7
      bind = $main_mod, 8, workspace, 8
      bind = $main_mod, 9, workspace, 9
      bind = $main_mod, 0, workspace, 10

      # Move active window to a workspace with main_mod + SHIFT + [0-9]
      bind = $main_mod SHIFT, 1, movetoworkspace, 1
      bind = $main_mod SHIFT, 2, movetoworkspace, 2
      bind = $main_mod SHIFT, 3, movetoworkspace, 3
      bind = $main_mod SHIFT, 4, movetoworkspace, 4
      bind = $main_mod SHIFT, 5, movetoworkspace, 5
      bind = $main_mod SHIFT, 6, movetoworkspace, 6
      bind = $main_mod SHIFT, 7, movetoworkspace, 7
      bind = $main_mod SHIFT, 8, movetoworkspace, 8
      bind = $main_mod SHIFT, 9, movetoworkspace, 9
      bind = $main_mod SHIFT, 0, movetoworkspace, 10

      # control volume,brightness,media players
      bind = ,XF86AudioRaiseVolume, exec, pamixer -i 5
      bind = ,XF86AudioLowerVolume, exec, pamixer -d 5
      bind = ,XF86AudioMute, exec, pamixer -t
      bind = ,XF86AudioMicMute, exec, pamixer --default-source -t
      bind = ,XF86MonBrightnessDown, exec, brightnessctl set 5%-
      bind = ,XF86MonBrightnessUp, exec, brightnessctl set +5%
      bind = ,XF86AudioPlay, exec, mpc -q toggle
      bind = ,XF86AudioNext, exec, mpc -q next
      bind = ,XF86AudioPrev, exec, mpc -q prev
    '';
  };
}
