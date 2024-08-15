#
# Desktop environment.
# src: https://www.gnome.org/
#

{ fileExplorer, pkgs, userSettings, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # GSettings editor for GNOME: https://apps.gnome.org/DconfEditor/
    dconf-editor
    # A simple color chooser written in GTK3: https://gitlab.gnome.org/World/gcolor3
    gcolor3
    # Gnome tweaks to change caps lock to Ctrl: https://gitlab.gnome.org/GNOME/gnome-tweaks
    gnome-tweaks
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
      "org/gnome/mutter/keybindings" = {
        switch-monitor = ["XF86Display"]; # Removing Super-p => used by spotify-toggle.

        # WARN: Keybindings available only on Ubuntu 22.
        toggle-tiled-left = ["<Super>h" "<Super>Left"];
        toggle-tiled-right = ["<Super>l" "<Super>Right"];
      };

      # org.gnome.desktop -------------------------------------------

      "org/gnome/desktop/wm/keybindings" = {
        close = ["<Super>q"];
        toggle-maximized = ["<Super>f"];
        toggle-fullscreen = ["<Super><Shift>f"];

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
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/audio-mixer/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/calculator/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/color-picker/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/file-manager-tui/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/file-manager-gui/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/logout/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/mpc-next/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/mpc-toggle/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/mpd-start/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/spotify/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/spotify-next/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/spotify-toggle/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/term/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/audio-mixer" = {
        name = "audio-mixer";
        command = "${userSettings.term} -e pulsemixer";
        binding = "<Super>a";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/calculator" = {
        name = "calculator";
        command = "${userSettings.term} -e numbat --intro-banner off";
        binding = "<Super>c";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/color-picker" = {
        name = "color-picker";
        command = "gcolor3";
        binding = "<Super><Shift>o";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/file-manager-tui" = {
        name = "file-explorer-tui";
        command = "${userSettings.term} -e ${userSettings.fileManager}";
        binding = "<Super>e";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/file-manager-gui" = {
        name = "file-explorer-gui";
        command = "nautilus";
        binding = "<Super><Shift>e";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/logout" = {
        name = "logout";
        command = "wlogout";
        binding = "<Super><Shift>w";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/mpc-next" = {
        name = "mpc-next";
        command = "mpc -q next";
        binding = "<Super><Shift>n";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/mpc-toggle" = {
        name = "mpc-toggle";
        command = "mpc -q toggle";
        binding = "<Super><Shift>p";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/mpd-start" = {
        name = "mpd-start";
        command = "${userSettings.term} -e ncmpcpp --screen visualizer";
        binding = "<Super><Shift>m";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/spotify" = {
        name = "spotify";
        command = "spotify";
        binding = "<Super>m";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/spotify-next" = {
        name = "spotify-next";
        command = "spotify-next";
        binding = "<Super>n";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/spotify-toggle" = {
        name = "spotify";
        command = "spotify-toggle";
        binding = "<Super>p";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/term" = {
        name = "term";
        command = "${userSettings.term} -e tmux -2 -u";
        binding = "<Super>t";
      };

      # org.gnome.shell -------------------------------------------

      "org/gnome/shell" = {
        favorite-apps = ["obsidian.desktop" "kitty.desktop" "floorp.desktop" "slack.desktop"];
        welcome-dialog-last-shown-version = "";

        disable-user-extensions = false;
        disabled-extensions = [
          "disabled"
          "ubuntu-dock@ubuntu.com"
          "ding@rastersoft.com"
        ];
      };
      "org/gnome/shell/keybindings" = {
        # Screenshot.
        show-screenshot-ui = ["Print" "<Super>s"];
        screenshot-window = ["<Alt>Print" "<Super><Shift>s"];

        # Display overview.
        # WARN: May not be available on Ubuntu 24! Use `toggle-application-view` instead.
        toggle-overview = ["<Super>space"];
        toggle-application-view = [];

        toggle-message-tray = ["<Super>v"]; # Removing key-binding Super-m => used by spotify.
        focus-active-notification = []; # Removing key-binding Super-n => used by spotify-next.
      };

      # WARN: Keybindings available only on Ubuntu 24.
      # "org/gnome/shell/extensions/tiling-assistant" = {
      #   # Move window to half of screen.
      #   tile-left-half-ignore-ta = ["<Super>h"];
      #   tile-right-half-ignore-ta = ["<Super>l"];
      # };
    };
  };
}
