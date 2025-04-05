#
# Install all apps and packages here.
#

{ userSettings, ... }: {

  # Install packages from nix's official package repository.
  #
  # The packages installed here are available to all users, and are reproducible across machines, and are rollbackable.
  # But on macOS, it's less stable than homebrew.
  #
  # Related Discussion: https://discourse.nixos.org/t/darwin-again/29331
  # environment.systemPackages = with pkgs; [
  #   neovim
  #   git
  #   just
  # ];
  environment.variables.EDITOR = userSettings.editor;

  # To make this work, homebrew need to be installed manually, see https://brew.sh
  #
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true; # Fetch the newest stable branch of Homebrew's git repo
      upgrade = true; # Upgrade outdated casks, formulae, and App Store apps
      # 'zap': uninstalls all formulae(and related files) not listed in the generated Brewfile
      #cleanup = "zap";
    };

    taps = [
      "homebrew-zathura/zathura"
      # Tap for JankyBorders.
      "FelixKratz/formulae"
    ];

    # `brew install`
    # To get the list of installed apps with brew: `brew list`
    brews = [
      # A lightweight window border system for macOS: https://github.com/FelixKratz/JankyBorders
      "borders"
      # A highly customizable and functional PDF viewer: https://git.pwmt.org/pwmt/zathura/
      "zathura"
    ];

    # `brew install --cask`
    # To get the list of installed apps with brew casks: `brew list --casks`
    casks = [
      # i3-like tiling window manager for macOS: https://github.com/nikitabobko/AeroSpace
      "aerospace"
      # 👻 Ghostty is a fast, feature-rich, and cross-platform terminal emulator that uses platform-native UI and GPU acceleration: https://ghostty.org/
      "ghostty"
      # macOS system monitor in your menu bar: https://github.com/exelban/stats
      "stats"
      # Knowledge base that works on top of a local folder of plain text Markdown files: https://obsidian.md/
      "obsidian"
      # Team communication and collaboration software: https://slack.com/
      "slack"
      # 🌀 Experience tranquillity while browsing the web without people tracking you: https://zen-browser.app/
      "zen-browser"

      # "anki"
      # "iina" # video player
      # "raycast" # (HotKey: alt/option + space)search, caculate and run scripts(with many plugins)
    ];
  };
}
