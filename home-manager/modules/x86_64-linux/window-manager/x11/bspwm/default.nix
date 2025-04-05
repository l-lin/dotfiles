#
# 
# src: 
#

{ pkgs, userSettings, ... }: {
  # HACK: DISABLED because I'm currently using native install of bspwm & sxhkd.
  # sudo apt install bspwm sxhkd
  # xsession.windowManager.bspwm = {
  #   enable = true;
  # };
  # services.sxhkd = {
  #   enable = true;
  # };

  home.packages = with pkgs; [ polybar ];

  programs.rofi = {
    enable = true;
  };

  xdg.configFile."bspwm" = {
    source = ./.config/bspwm;
    recursive = true;
  };
  xdg.configFile."sxhkd/sxhkdrc".text = ''
#
# bspmwm management
#

# Move / Focus desktops.
super + {_,shift + }{1-5,0}
  bspc {desktop --focus,node --to-desktop} '{1,2,3,4,5}'

# Move / Focus nodes.
super + {_,shift + }{h,j,k,l}
	bspc node -{f,s} {west,south,north,east}

# Brightness control.
# TODO: Not working, the command works, but the brightness is not updated...
XF86MonBrightness{Down,Up}
	brightnessctl set {5%-,+5%}

XF86AudioRaiseVolume
  pamixer -i 5

XF86AudioLowerVolume
  pamixer -d 5

XF86AudioMute
  pamixer -t

# Close / Kill a node.
super + {_,shift + }q
  bspc node -{c,k}

# Toggle fullscreen.
super + f
  bspc node -t ~fullscreen

# Reload sxhkd.
super + Escape
  pkill -USR1 -x sxhkd

# Quit/Reload bspmwm.
super + control + {q,r}
  bspc {quit,wm -r}

#
# Applications
#

# Audio mix.
super + a
  ${userSettings.term} -e pulsemixer

# Calculator.
super + c
  ${userSettings.term} -e numbat --intro-banner off

# File manager.
super + e
  ${userSettings.term} -e yazi

# Terminal.
super + t
  ${userSettings.term} -e tmux -2 -u

# Window switcher, run dialog and dmenu replacement.
super + space
  rofi -show drun
  '';
  xdg.configFile."polybar" = {
    source = ./.config/polybar;
    recursive = true;
  };
}
