{ config, pkgs, ... }: 
let
  palette = config.colorScheme.palette;
  betterTransition = "all 0.3s cubic-bezier(.55,-0.68,.48,1.682)";
in {
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;
    settings = [
      {
        layer = "top";
        position = "top";
        modules-center = [ "hyprland/workspaces" ];
        modules-left = [
          "custom/startmenu"
          "hyprland/window"
          "pulseaudio"
          "cpu"
          "memory"
          "idle_inhibitor"
        ];
        modules-right = [
          "custom/hyprbindings"
          "custom/themeselector"
          "custom/notification"
          "custom/exit"
          "battery"
          "tray"
          "clock"
        ];

        "hyprland/workspaces" = {
          format = "{name}";
          format-icons = {
            default = " ";
            active = " ";
            urgent = " ";
          };
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
        };
        "clock" = {
          format = '' {:L%H:%M}'';
          tooltip = true;
          tooltip-format = "<big>{:%A, %d.%B %Y }</big>\n<tt><small>{calendar}</small></tt>";
        };
        "hyprland/window" = {
          max-length = 22;
          separate-outputs = false;
          rewrite = {
            "" = " 🙈 No Windows? ";
          };
        };
        "memory" = {
          interval = 5;
          format = " {}%";
          tooltip = true;
        };
        "cpu" = {
          interval = 5;
          format = " {usage:2}%";
          tooltip = true;
        };
        "disk" = {
          format = " {free}";
          tooltip = true;
        };
        "network" = {
          format-icons = [
            "󰤯"
            "󰤟"
            "󰤢"
            "󰤥"
            "󰤨"
          ];
          format-ethernet = " {bandwidthDownOctets}";
          format-wifi = "{icon} {signalStrength}%";
          format-disconnected = "󰤮";
          tooltip = false;
        };
        "tray" = {
          spacing = 12;
        };
        "pulseaudio" = {
          format = "{icon} {volume}% {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = " {format_source}";
          format-source = " {volume}%";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
            ];
          };
          on-click = "sleep 0.1 && pavucontrol";
        };
        "custom/themeselector" = {
          tooltip = false;
          format = "";
          on-click = "sleep 0.1 && theme-selector";
        };
        "custom/exit" = {
          tooltip = false;
          format = "";
          on-click = "sleep 0.1 && wlogout";
        };
        "custom/startmenu" = {
          tooltip = false;
          format = "";
          # exec = "rofi -show drun";
          on-click = "sleep 0.1 && wofi";
        };
        "custom/hyprbindings" = {
          tooltip = false;
          format = "󱕴";
          on-click = "sleep 0.1 && list-hypr-bindings";
        };
        "idle_inhibitor" = {
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
          };
          tooltip = "true";
        };
        "custom/notification" = {
          tooltip = false;
          format = "{icon} {}";
          format-icons = {
            notification = "<span foreground='red'><sup></sup></span>";
            none = "";
            dnd-notification = "<span foreground='red'><sup></sup></span>";
            dnd-none = "";
            inhibited-notification = "<span foreground='red'><sup></sup></span>";
            inhibited-none = "";
            dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
            dnd-inhibited-none = "";
          };
          return-type = "json";
          exec-if = "which swaync-client";
          exec = "swaync-client -swb";
          on-click = "sleep 0.1 && task-waybar";
          escape = true;
        };
        "battery" = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = "󱘖 {capacity}%";
          format-icons = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
          on-click = "";
          tooltip = false;
        };
      }
    ];
    style = ''
      * {
        font-size: 16px;
        border-radius: 0px;
        border: none;
        font-family: JetBrainsMono Nerd Font Mono;
        min-height: 0px;
      }
        window#waybar {
        background-color: #${palette.base00};
      }
      #workspaces {
        color: #${palette.base00};
        background: #${palette.base01};
        margin: 4px 4px;
        padding: 8px 5px;
        border-radius: 16px;
      }
      #workspaces button {
        font-weight: bold;
        padding: 0px 5px;
        margin: 0px 3px;
        border-radius: 16px;
        color: #${palette.base00};
        background: linear-gradient(45deg, #${palette.base0E}, #${palette.base0F}, #${palette.base0D}, #${palette.base09});
        background-size: 300% 300%;
        animation: gradient_horizontal 15s ease infinite;
        opacity: 0.5;
        transition: ${betterTransition};
      }
      #workspaces button.active {
        font-weight: bold;
        padding: 0px 5px;
        margin: 0px 3px;
        border-radius: 16px;
        color: #${palette.base00};
        background: linear-gradient(45deg, #${palette.base0E}, #${palette.base0F}, #${palette.base0D}, #${palette.base09});
        background-size: 300% 300%;
        animation: gradient_horizontal 15s ease infinite;
        transition: ${betterTransition};
        opacity: 1.0;
        min-width: 40px;
      }
      #workspaces button:hover {
        font-weight: bold;
        border-radius: 16px;
        color: #${palette.base00};
        background: linear-gradient(45deg, #${palette.base0E}, #${palette.base0F}, #${palette.base0D}, #${palette.base09});
        background-size: 300% 300%;
        animation: gradient_horizontal 15s ease infinite;
        opacity: 0.8;
        transition: ${betterTransition};
      }
      @keyframes gradient_horizontal {
        0% {
          background-position: 0% 50%;
        }
        50% {
          background-position: 100% 50%;
        }
        100% {
          background-position: 0% 50%;
        }
      }
      @keyframes swiping {
        0% {
          background-position: 0% 200%;
        }
        100% {
          background-position: 200% 200%;
        }
      }
      tooltip {
        background: #${palette.base00};
        border: 1px solid #${palette.base0E};
        border-radius: 12px;
      }
      tooltip label {
        color: #${palette.base07};
      }
      #window, #pulseaudio, #cpu, #memory, #idle_inhibitor {
        font-weight: bold;
        margin: 4px 0px;
        margin-left: 7px;
        padding: 0px 18px;
        color: #${palette.base05};
        background: #${palette.base01};
        border-radius: 24px 10px 24px 10px;
      }
      #custom-startmenu {
        color: #${palette.base0D};
        background: #${palette.base01};
        font-size: 28px;
        margin: 0px;
        padding: 0px 30px 0px 15px;
        border-radius: 0px 0px 40px 0px;
      }
      #custom-hyprbindings, #network, #custom-themeselector, #battery,
      #custom-notification, #tray, #custom-exit {
        font-weight: bold;
        background: #${palette.base01};
        color: #${palette.base05};
        margin: 4px 0px;
        margin-right: 7px;
        border-radius: 10px 24px 10px 24px;
        padding: 0px 18px;
      }
      #clock {
        font-weight: bold;
        color: #${palette.base00};
        background: linear-gradient(45deg, #${palette.base0C}, #${palette.base0F}, #${palette.base0B}, #${palette.base08});
        background-size: 300% 300%;
        animation: gradient_horizontal 15s ease infinite;
        margin: 0px;
        padding: 0px 15px 0px 30px;
        border-radius: 0px 0px 0px 40px;
      }
    '';
  };
}
