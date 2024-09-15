#
# Desktop environment.
# src: https://www.gnome.org/
#

{ fileExplorer, pkgs, userSettings, ... }: let
  # Ubuntu 20.04 is using gnome 42.
  # However, nixpkgs seems to only takes the 3 latest gnome versions (which is currently 44, 45 and 46).
  # See https://github.com/NixOS/nixpkgs/blob/d0bac0dc755a3b62d2edcdb6a1152beefe50231a/pkgs/desktops/gnome/extensions/default.nix#L69.
  pkgs-22 = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-22.11.tar.gz";
    sha256 = "1xi53rlslcprybsvrmipm69ypd3g3hr7wkxvzc73ag8296yclyll";
  }) { inherit (pkgs) system; };
in {
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

    # GNOME EXTENSIONS
    # You can find the list of gnome extensions here with their gnome version compatibilities:
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/desktops/gnome/extensions/extensions.json

    # Keyboard-driven layer for GNOME Shell: https://github.com/pop-os/shell
    pkgs-22.gnomeExtensions.pop-shell
    pkgs-22.gnomeExtensions.vitals
  ];

  # Get the list of gnome settings by running `dconf-editor`.
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

        # WARN: Keybindings available only on Ubuntu 20.
        #toggle-tiled-left = ["<Super>h" "<Super>Left"];
        #toggle-tiled-right = ["<Super>l" "<Super>Right"];
      };

      # org.gnome.desktop -------------------------------------------

      "org/gnome/desktop/wm/keybindings" = {
        close = ["<Super>q"];
        toggle-maximized = ["<Super>f"];
        toggle-fullscreen = ["<Super><Shift>f"];

        minimize = []; # default was Super-h => used by tile-left-half-ignore-ta.

        # Move window to monitors.
        #move-to-monitor-left = ["<Super><Shift>h"];
        #move-to-monitor-right = ["<Super><Shift>l"];
        move-to-workspace-1 = ["<Super><Shift>1"];
        move-to-workspace-2 = ["<Super><Shift>2"];
        move-to-workspace-3 = ["<Super><Shift>3"];
        move-to-workspace-4 = ["<Super><Shift>4"];
        move-to-workspace-5 = ["<Super><Shift>5"];

        switch-to-workspace-1 = ["<Super>1"];
        switch-to-workspace-2 = ["<Super>2"];
        switch-to-workspace-3 = ["<Super>3"];
        switch-to-workspace-4 = ["<Super>4"];
        switch-to-workspace-5 = ["<Super>5"];

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
        # Get the list of enabled extension names by running `gnome-extensions list`.
        # You can get the extension name directly from nix store:
        # `ls /nix/store/abc-gnome-shell-extension-highlight-focus-12/share/gnome-shell/extensions/`
        # Or using `pkgs.gnomeExtensions.<package-name>.extensionUuid`
        enabled-extensions = with pkgs-22.gnomeExtensions; [
          pop-shell.extensionUuid
          vitals.extensionUuid
        ];

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

        # Remove default keybindings for switching to applications (using to switch to workspaces).
        switch-to-application-1 = [];
        switch-to-application-2 = [];
        switch-to-application-3 = [];
        switch-to-application-4 = [];
        switch-to-application-5 = [];
      };

      # WARN: Keybindings available only on Ubuntu 24.
      # "org/gnome/shell/extensions/tiling-assistant" = {
      #   # Move window to half of screen.
      #   tile-left-half-ignore-ta = ["<Super>h"];
      #   tile-right-half-ignore-ta = ["<Super>l"];
      # };

      # org.gnome.shell.extensions -------------------------------------------

      "org/gnome/shell/extensions/pop-shell" = {
        active-hint = true;
        tile-by-default = true;
      };
    };
  };
}
