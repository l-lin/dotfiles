#
#  macOS's System configuration
#
#  All the configuration options are documented here:
#    https://daiderd.com/nix-darwin/manual/index.html#sec-options
#  Incomplete list of macOS `defaults` commands :
#    https://github.com/yannbertrand/macos-defaults
#

{ pkgs, systemSettings, ... }: {
  system = {
    stateVersion = 5;
    # activationScripts are executed every time you boot the system or run `nixos-rebuild` / `darwin-rebuild`.
    activationScripts.postUserActivation.text = ''
      # activateSettings -u will reload the settings from the database and apply them to the current session,
      # so we do not need to logout and login again to make the changes take effect.
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

    defaults = {
      menuExtraClock.Show24Hour = true; # show 24 hour clock

      # Customize dock.
      dock = {
        autohide = true;
        show-recents = false;

        # Disable Hot Corners, no need for them.
        # src: https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-system.defaults.dock.wvous-bl-corner
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
      };

      # Customize finder.
      finder = {
        _FXShowPosixPathInTitle = true; # show full path in finder title
        AppleShowAllExtensions = true; # show all file extensions
        FXEnableExtensionChangeWarning = false; # disable warning when changing file extension
        FXRemoveOldTrashItems = true; # remove items in the trash after 30 days
        QuitMenuItem = true; # enable quit menu item
        ShowPathbar = true; # show path bar
        ShowStatusBar = true; # show status bar
      };

      # customize trackpad
      trackpad = {
        # enable tap to click
        Clicking = true;
        # enable two finger right click
        TrackpadRightClick = true;
        # enable three finger drag
        TrackpadThreeFingerDrag = true;
      };

      controlcenter = {
        # Show a battery percentage in menu bar.
        BatteryShowPercentage = true;
        # Show a bluetooth control in menu bar.
        Bluetooth = false;
        # Show a Screen Brightness control in menu bar.
        Display = false;
        # Show a Focus control in menu bar.
        FocusModes = false;
        # Show a sound control in menu bar.
        Sound = false;
      };

      universalaccess = {
        # Disable transparency in the menu bar and elsewhere.
        reduceTransparency = true;
      };

      # Customize settings that not supported by nix-darwin directly
      # Incomplete list of macOS `defaults` commands :
      #   https://github.com/yannbertrand/macos-defaults
      NSGlobalDomain = {
        # `defaults read NSGlobalDomain "xxx"`

        # Enable natural scrolling (default to true)
        "com.apple.swipescrolldirection" = true;
        # Disable beep sound when pressing volume up/down key.
        "com.apple.sound.beep.feedback" = 0;
        # Use F1, F2, etc. keys as standard function keys.
        "com.apple.keyboard.fnState" = true;

        # Set to ‘Dark’ to enable dark mode, or leave unset for normal mode.
        # /!\ It does not automatically change the theme...
        #AppleInterfaceStyle = null;
        # Mode 3 enables full keyboard control.
        AppleKeyboardUIMode = 3;
        # Enable press and hold (annoying pop-up when navigating in nvim).
        # src: https://apple.stackexchange.com/q/332769
        ApplePressAndHoldEnabled = false;
        # Jump to the spot that’s clicked on the scroll bar.
        AppleScrollerPagingBehavior = true;
        # Whether to always show hidden files.
        AppleShowAllFiles = true;
        # Only show scroll bar when scrolling.
        AppleShowScrollBars = "WhenScrolling";

        # If you press and hold certain keyboard keys when in a text area, the key’s character begins to repeat.
        # Sets how long it takes before it starts repeating.
        # Normal minimum is 15 (225 ms), maximum is 120 (1800 ms)
        InitialKeyRepeat = 15;
        # Sets how fast it repeats once it starts.
        # Normal minimum is 2 (30 ms), maximum is 120 (1800 ms).
        KeyRepeat = 3;

        NSAutomaticCapitalizationEnabled = false; # disable auto capitalization
        NSAutomaticDashSubstitutionEnabled = false; # disable auto dash substitution
        NSAutomaticPeriodSubstitutionEnabled = false; # disable auto period substitution
        NSAutomaticQuoteSubstitutionEnabled = false; # disable auto quote substitution
        NSAutomaticSpellingCorrectionEnabled = false; # disable auto spelling correction
        NSAutomaticWindowAnimationsEnabled = false; # whether to animate opening and closing of windows and popovers
        NSDocumentSaveNewDocumentsToCloud = false; # whether to save new documents to iCloud by default
        NSNavPanelExpandedStateForSaveMode = true; # expand save panel by default
        NSNavPanelExpandedStateForSaveMode2 = true;
        # Sets the size of the finder sidebar icons: 1 (small), 2 (medium) or 3 (large).
        NSTableViewDefaultSizeMode = 1;
        NSWindowShouldDragOnGesture = true; # whether to enable moving window by holding anywhere on it like on Linux
      };

      # Customize settings that not supported by nix-darwin directly
      # see the source code of this project to get more undocumented options:
      #    https://github.com/rgcr/m-cli
      #
      # All custom entries can be found by running `defaults read` command.
      # or `defaults read xxx` to read a specific domain.
      CustomUserPreferences = {
        # ".GlobalPreferences" = {
        #   # automatically switch to a new space when switching to the application
        #   AppleSpacesSwitchOnActivate = true;
        # };
        NSGlobalDomain = {
          # Add a context menu item for showing the Web Inspector in web views
          WebKitDeveloperExtras = true;
        };
        "com.apple.finder" = {
          ShowExternalHardDrivesOnDesktop = true;
          ShowHardDrivesOnDesktop = true;
          ShowMountedServersOnDesktop = true;
          ShowRemovableMediaOnDesktop = true;
          _FXSortFoldersFirst = true;
          # When performing a search, search the current folder by default
          FXDefaultSearchScope = "SCcf";
          # Show the pathbar in the Finder
          ShowPathbar = true;
        };
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.spaces" = {
          "spans-displays" = 0; # Display have separate spaces
        };
        "com.apple.WindowManager" = {
          EnableStandardClickToShowDesktop = 0; # Click wallpaper to reveal desktop
          StandardHideDesktopIcons = 0; # Show items on desktop
          HideDesktop = 0; # Do not hide items on desktop & stage manager
          StageManagerHideWidgets = 0;
          StandardHideWidgets = 0;
        };
        "com.apple.screensaver" = {
          # Require password immediately after sleep or screen saver begins
          askForPassword = 1;
          askForPasswordDelay = 0;
        };
        "com.apple.screencapture" = {
          location = "~/Desktop";
          type = "png";
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        # Prevent Photos from opening automatically when devices are plugged in
        "com.apple.ImageCapture".disableHotPlug = true;
      };

      loginwindow = {
        GuestEnabled = false; # disable guest user
        SHOWFULLNAME = true; # show full name in login window
      };
    };

    # Remap keys to fit my muscle memory!
    keyboard = {
      enableKeyMapping = true;

      remapCapsLockToControl = true; # remap caps lock to control
      remapCapsLockToEscape  = false; # remap caps lock to escape

      # swap left command and left alt
      # so it matches common keyboard layout: `ctrl | command | alt`
      # which is the common layout for other keyboards...
      swapLeftCommandAndLeftAlt = true;
    };
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  # this is required if you want to use darwin's default shell - zsh
  programs.zsh = {
    enable = true;
    # No need for completion, let me configure them myself.
    enableBashCompletion = false;
    enableCompletion = false;
    # Skip system wide compinit, let ourself do it for faster startup time!
    enableGlobalCompInit = false;
  };
  environment.shells = [
    pkgs.zsh
  ];

  # Set your time zone.
  time.timeZone = systemSettings.timezone;
}
