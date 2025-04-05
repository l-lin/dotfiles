#
# Desktop environment.
# To know which gnome version you're using, run `gnome-shell --version`.
#
# src: https://www.gnome.org/
#

{ config, fileExplorer, lib, pkgs, userSettings, ... }: let
  # Nixpkgs seems to only takes the 3 latest gnome versions (which is currently 44, 45 and 46).
  # So if you need to get the gnome extensions from an older version of nixpkgs,
  # you will need to get from an older nixpkgs archive.
  # src: https://github.com/NixOS/nixpkgs/blob/d0bac0dc755a3b62d2edcdb6a1152beefe50231a/pkgs/desktops/gnome/extensions/default.nix#L69.
  #
  # Example for getting Gnome v22:
  #
  # ```
  # pkgs-22 = import (builtins.fetchTarball {
  #   url = "https://github.com/NixOS/nixpkgs/archive/nixos-22.11.tar.gz";
  #   sha256 = "1xi53rlslcprybsvrmipm69ypd3g3hr7wkxvzc73ag8296yclyll";
  # }) { inherit (pkgs) system; };
  # ```
  #
  # Then instead of importing with standard pkgs:
  #
  # ```nix
  # home.packages = [ pkgs-22.gnomeExtensions.pop-shell ];
  # ```

  palette = config.lib.stylix.colors.withHashtag;
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

    # Tweak Tool to Customize GNOME Shell, Change the Behavior and Disable UI Elements: https://extensions.gnome.org/extension/3843/just-perfection.
    gnomeExtensions.just-perfection
    # Keyboard-driven layer for GNOME Shell: https://github.com/pop-os/shell.
    gnomeExtensions.pop-shell
    # A glimpse into your computer's temperature, voltage, fan speed, memory usage, processor load, system resources, network speed and storage stats: https://extensions.gnome.org/extension/1460/vitals/
    gnomeExtensions.vitals
  ];

  # Get the list of gnome settings by running `dconf-editor`.
  dconf = {
    enable = true;
    # NOTE: Settings to write to the dconf configuration system.
    # Note that the database is strongly-typed so you need to use the same types as described in the GSettings schema. For example, if an option is of type
    # `uint32` (`u`), you need to wrap the number using the `lib.hm.gvariant.mkUint32` constructor.
    # Otherwise, since Nix integers are implicitly coerced to `int32` (`i`), it would get stored in the database as such, and GSettings
    # might be confused when loading the setting.
    # You can find the list of gnome settings by executing `dconf-editor`.
    # src: https://github.com/nix-community/home-manager/blob/e524c57b1fa55d6ca9d8354c6ce1e538d2a1f47f/modules/misc/dconf.nix#L60-L73
    settings = {
      # org.gnome.mutter -------------------------------------------

      "org/gnome/mutter" = {
        # Disable Super to trigger window overview.
        overlay-key = "";

        # Disable dynamic workspaces, use fixed workspaces instead.
        dynamic-workspaces = false;
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

        # NOTE: pop-shell keybindings:
        # <Super><Enter>: to activate window management mode.
        # <Super>o: toggle orientation of a fork's tiling orientation.
        # <Super>g: toggle window between floating and tiling.
      };
      "org/gnome/desktop/interface" = {
        clock-show-weekday = true;
        show-battery-percentage = true;
      };
      "org/gnome/desktop/wm/preferences" = {
        # Buttons top right to minimize, maximize or close the window.
        button-layout = ":minimize,maximize,close";

        # Fixed workspace.
        num-workspaces = 5;

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
        favorite-apps = ["obsidian.desktop" "kitty.desktop" "slack.desktop"];
        welcome-dialog-last-shown-version = "";

        disable-user-extensions = false;
        # Get the list of enabled extension names by running `gnome-extensions list`.
        # You can get the extension name directly from nix store:
        # `ls /nix/store/abc-gnome-shell-extension-highlight-focus-12/share/gnome-shell/extensions/`
        # Or using `pkgs.gnomeExtensions.<package-name>.extensionUuid`
        enabled-extensions = with pkgs.gnomeExtensions; [
          just-perfection.extensionUuid
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
        show-screenshot-ui = ["Print" "<Super><Shift>s"];
        screenshot-window = ["<Alt>Print"];

        # Display overview.
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

      # org.gnome.shell.extensions -------------------------------------------

      "org/gnome/shell/extensions/just-perfection" = {
        # Remove useless Activities button (button from top-left).
        activities-button = false;
        # No need for animations, let's go faaast.
        animation = 0;
        # No need to display the app menu, which is the current window menu context.
        app-menu = false;
        # When GNOME Shell is starting up for the first time, display the Desktop directly.
        startup-status = 0;
      };

      "org/gnome/shell/extensions/pop-shell" = with lib.hm.gvariant; {
        # Highlight the active window.
        active-hint = true;
        active-hint-border-radius = mkUint32 8;
        # Change the active window border color.
        # src:
        # - https://github.com/pop-os/shell/issues/1582
        # - https://github.com/NixOS/nixpkgs/issues/256889
        hint-color-rgba = palette.base05;

        # Gaps between windows.
        gap-inner = mkUint32 2;
        gap-outer = mkUint32 2;

        # Remove gaps if there's only one window.
        smart-gaps = false;

        # Tile mode by default.
        tile-by-default = true;

        # Move mouse cursor to the center of the window.
        # FIXME: This does not seem to work on Wayload unfortunately :(
        # src: https://github.com/pop-os/shell/discussions/1201
        mouse-cursor-focus-location = mkUint32 4;
        mouse-cursor-follows-active-window = true;
      };

      "org/gnome/shell/extensions/vitals" = {
        # Position of the vitals panel: 0 == left.
        position-in-panel = 0;
      };
    };
  };

  # Disable gnome-screenshot shutter sound.
  # src: https://unix.stackexchange.com/a/735126
  xdg.dataFile."sounds/__custom/screen-capture.disabled".text = "";
}
