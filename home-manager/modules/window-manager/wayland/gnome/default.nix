#
# Desktop environment.
# src: https://www.gnome.org/
#

{ pkgs, userSettings, ... }: with pkgs; {
  home.packages = [
    # GSettings editor for GNOME: https://apps.gnome.org/DconfEditor/
    dconf-editor
    # Gnome tweaks to change caps lock to Ctrl: https://gitlab.gnome.org/GNOME/gnome-tweaks
    gnome-tweaks
    # # Hides the top bar, except in overview. However, there is an option to show the panel whenever the mouse pointer approaches the edge of the screen. And if "intellihide" is enabled, the panel only hides when a window takes the space: https://extensions.gnome.org/extension/545/hide-top-bar/
    # gnomeExtensions.hide-top-bar
    # # Tweak Tool to Customize GNOME Shell, Change the Behavior and Disable UI Elements: https://extensions.gnome.org/extension/3843/just-perfection/
    # gnomeExtensions.just-perfection
    # # Keyboard-driven layer for GNOME Shell: https://github.com/pop-os/shell
    # gnomeExtensions.pop-shell
  ];
  dconf = {
    enable = true;
    settings = {
      "org/gnome/shell" = {
        favorite-apps = ["obsidian.desktop" "kitty.desktop" "firefox.desktop"];
        welcome-dialog-last-shown-version = "";

        disable-user-extensions = false;
        disabled-extensions = [
          "disabled"
          "ubuntu-dock@ubuntu.com"
          "ding@rastersoft.com"
        ];
        # TODO: I cannot add new gnome extensions, there are not installed, I don't understand why...
        # enabled-extensions = with pkgs.gnomeExtensions; [
        #   # Hides the top bar, except in overview. However, there is an option to show the panel whenever the mouse pointer approaches the edge of the screen. And if "intellihide" is enabled, the panel only hides when a window takes the space: https://extensions.gnome.org/extension/545/hide-top-bar/
        #   hide-top-bar.extensionUuid
        #   # Tweak Tool to Customize GNOME Shell, Change the Behavior and Disable UI Elements: https://extensions.gnome.org/extension/3843/just-perfection/
        #   just-perfection.extensionUuid
        #   # Keyboard-driven layer for GNOME Shell: https://github.com/pop-os/shell
        #   pop-shell.extensionUuid
        # ];
      };
      # "org/gnome/shell/extensions/hidetopbar" = {
      #   enable-active-window = false;
      #   enable-intellihide = false;
      # };
      "org/gnome/shell/keybindings" = {
        show-screenshot-ui = ["Print" "<Super>s"];
        screenshot-window = ["<Alt>Print" "<Super><Shift>s"];

      };
      "org/gnome/shell/extensions/tiling-assistant" = {
        tile-left-half-ignore-ta = ["<Super>h"];
        tile-right-half-ignore-ta = ["<Super>l"];
      };

      "org/gnome/desktop/interface" = {
        clock-show-weekday = true;
        show-battery-percentage = true;
      };
      "org/gnome/desktop/wm/preferences" = {
        button-layout = ":minimize,maximize,close";
      };
      "org/gnome/desktop/wm/keybindings" = {
        close = ["<Super>q"];
        toggle-maximized = ["<Super>f"];
        minimize = [];
      };
      "org/gnome/settings-daemon/plugins/media-keys" = {
        screensaver = ["<Super>w"];

        terminal = "disabled";

        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "kitty";
        # TODO: fix kitty installation from home-manager then replace with `kitty` instead.
        command = "/home/${userSettings.username}/.local/kitty.app/bin/kitty -e tmux -2 -u";
        binding = "<Super>t";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "file explorer";
        command = "nautilus";
        binding = "<Super>e";
      };
    };
  };
}
