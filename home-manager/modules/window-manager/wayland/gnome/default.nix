#
# Desktop environment.
# src: https://www.gnome.org/
#

{ pkgs, ... }: with pkgs; {
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

    # Copy/paste utilities: https://github.com/bugaevc/wl-clipboard
    wl-clipboard
  ];
  dconf = {
    enable = true;
    settings = {
      # org.gnome.mutter -------------------------------------------

      "org/gnome/mutter" = {
        # Disable Super to trigger window overview
        overlay-key = "";
      };

      # org.gnome.desktop -------------------------------------------

      "org/gnome/desktop/wm/keybindings" = {
        close = ["<Super>q"];
        toggle-maximized = ["<Super>f"];

        minimize = []; # default was Super-h => used by tile-left-half-ignore-ta.

        # Move window to monitors.
        move-to-monitor-left = ["<Super><Shift>h"];
        move-to-monitor-right = ["<Super><Shift>l"];

        switch-input-source = ["XF86Keyboard"]; # disable Super-space => used by toggle-application-view.
        switch-input-source-backward = ["<Shift>XF86Keyboard"];
      };
      "org/gnome/desktop/interface" = {
        clock-show-weekday = true;
        show-battery-percentage = true;
      };
      "org/gnome/desktop/wm/preferences" = {
        # Buttons top right to minimize, maximize or close the window.
        button-layout = ":minimize,maximize,close";

        # Only visually alert, no need to have sound polution.
        audible-bell = false;
        visual-bell = false;
      };

      # org.gnome.settings-daemon -------------------------------------------

      "org/gnome/settings-daemon/plugins/media-keys" = {
        screenreader = []; # default was <Alt><Super>s => used by screenshot-window.
        screensaver = ["<Super>w"];

        terminal = "disabled";

        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "kitty";
        command = "kitty -e tmux -2 -u";
        binding = "<Super>t";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "file-explorer";
        command = "nautilus";
        binding = "<Super>e";
      };

      # org.gnome.shell -------------------------------------------

      "org/gnome/shell" = {
        favorite-apps = ["obsidian.desktop" "kitty.desktop" "firefox_firefox.desktop"];
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
        # Screenshot.
        show-screenshot-ui = ["Print" "<Super>s"];
        screenshot-window = ["<Alt>Print" "<Super><Shift>s"];

        # Display all application view.
        toggle-application-view = ["<Super>space"];
      };
      "org/gnome/shell/extensions/tiling-assistant" = {
        # Move window to half of screen.
        tile-left-half-ignore-ta = ["<Super>h"];
        tile-right-half-ignore-ta = ["<Super>l"];
      };
    };
  };
}
