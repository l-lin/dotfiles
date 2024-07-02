#
# Highly customizable Wayland bar for Sway and Wlroots based compositors.
# src: https://github.com/alexays/waybar
#

{ config, userSettings, ... }:
let
  palette = config.lib.stylix.colors;
in {
  programs.waybar = {
    enable = true;
  };

  # Symlink to ~/.config/waybar
  xdg.configFile."waybar/config.jsonc".text = ''
// https://github.com/Alexays/Waybar/wiki/Home
{
  "layer": "top",
  "position": "top",
  "output": "eDP-1",
  "height": 60,
  "spacing": 15,
  "margin-top": 15,
  "margin-left": 15,
  "margin-bottom": 0,
  "margin-right": 15,

  "modules-left": ["user", "disk", "memory", "cpu", "temperature", "tray"],
  "modules-center": ["hyprland/workspaces"],
  "modules-right": ["privacy", "pulseaudio", "battery", "backlight", "network", "bluetooth", "clock", "custom/exit"],

  // LEFT -----------------------------------------------------------
  "user": {
    "interval": "86400",
    "format": "",
    "icon": true
  },
  "disk": {
    "format": "󰒋 {free}",
    "on-click": "${userSettings.term} --class floating -e yazi"
  },
  "memory": {
    "format": "  {percentage}%",
    "on-click": "${userSettings.term} --class floating -e btop"
  },
  "cpu": {
    "format": "  {usage}%",
    "on-click": "${userSettings.term} --class floating -e btop"
  },
  "temperature": {
    "format": " {temperatureC}°C",
    "on-click": "${userSettings.term} --class floating -e btop",
    "critical-threshold": 90,
    // $ # Find the right thermal zone for your CPU by using the following command:
    // $ for f in /sys/class/thermal/thermal_zone*; do
    //  echo "$f $(cat $f/type) $(cat $f/temp)" | column -t | sed 's/\(.\)..$/.\1°C/'
    // done
    // /sys/class/thermal/thermal_zone0  INT3400  Thermal  20.0°C
    // /sys/class/thermal/thermal_zone1  pch_cannonlake  47.0°C
    // /sys/class/thermal/thermal_zone2  TMEM  42.0°C
    // /sys/class/thermal/thermal_zone3  acpitz  25.0°C
    // /sys/class/thermal/thermal_zone4  TSKN  44.0°C
    // /sys/class/thermal/thermal_zone5  NGFF  36.0°C
    // /sys/class/thermal/thermal_zone6  B0D4  50.0°C
    // /sys/class/thermal/thermal_zone7  x86_pkg_temp  55.0°C
    // /sys/class/thermal/thermal_zone8  iwlwifi_1  44.0°C
    // $ # Here, the thermal zone to use is 7.
    // src: https://askubuntu.com/a/854029
    "thermal-zone": 7
  },
  "tray": {
    "icon-size": 16,
    "spacing": 16,
    "show-passive-items": true
  },

  // CENTER -----------------------------------------------------------
  "hyprland/workspaces": {
    "format": "{icon}",
    "on-click": "activate",
    "format-icons": {
      "1": "󰠮",
      "2": "",
      "3": "󰈹",
      "4": ""
    },
    "icon-size": 50,
    "sort-by-number": true,
    "persistent-workspaces": {
      "*": 4
    }
  },

  // RIGHT -----------------------------------------------------------
  "pulseaudio": {
    "format": "{icon}  {volume}% {format_source}",
    "format-muted": "  {format_source}",
    "format-source": " {volume}%",
    "format-source-muted": " ",
    "format-icons": {
      "headphone": "",
      "hands-free": "󱡏",
      "headset": "",
      "phone": "",
      "portable": "",
      "car": "",
      "default": [ "", "", "" ]
    },
    "max-volume": 100,
    "scroll-step": 5,
    "on-click": "${userSettings.term} --class floating -e pulsemixer"
  },
  "battery": {
    "interval": 60,
    "format": "{icon}  {capacity}%",
    "format-icons": [
      "󰁺",
      "󰁻",
      "󰁼",
      "󰁽",
      "󰁾",
      "󰁿",
      "󰂀",
      "󰂁",
      "󰂂",
      "󰁹"
    ],
    "format-charging": "󰂄 {capacity}%",
    "states": {
      "warning": 30,
      "critical": 15
    }
  },
  "backlight": {
    "format": "{icon} ",
    "format-icons": ["", "", "", "", "", "", "", "", ""]
  },
  "network": {
    "format": "",
    "format-ethernet": "󰈁 ",
    "format-wifi": "{icon} ",
    "format-disconnected": "󰤮 ",
    "format-icons": ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"],
    "tooltip-format-wifi": "{essid} ({signalStrength}%)",
    "tooltip-format-ethernet": "{ifname}",
    "tooltip-format-disconnected": "Disconnected",
    "on-click": "${userSettings.term} --class floating -e nmtui connect"
  },
  "bluetooth": {
    "format": "󰂯",
    "format-disabled": "󰂲",
    "format-connected": "󰂱",
    "tooltip-format": "{controller_alias}\t{controller_address}",
    "tooltip-format-connected": "{controller_alias}\t{controller_address}\n\n{device_enumerate}",
    "tooltip-format-enumerate-connected": "{device_alias}\t{device_address}",
    "on-click": "${userSettings.term} --class floating -e bluetoothctl"
  },
  "clock": {
    "format": "󰃭 {:%Y-%m-%d %H:%M}",
    "on-click": "${userSettings.term} --class floating -e calcure"
  },
  "custom/exit": {
    "tooltip": false,
    "format": "",
    "on-click": "sleep 0.1 && wlogout"
  }
}

  '';
  xdg.configFile."waybar/style.css".source = ./config/style.css;
  xdg.configFile."waybar/colorscheme.css".text = ''
@define-color fg #${palette.base05};
@define-color fg-alt #${palette.base00};
@define-color bg #${palette.base00};
@define-color bg-alt #${palette.base0D};
@define-color green #${palette.base0B};
@define-color yellow #${palette.base0A};
@define-color red #${palette.base08};
  '';
}
