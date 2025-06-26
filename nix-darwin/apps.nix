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
      # - "none" (the default): formulae not present in the generated Brewfile are left installed.
      # - "uninstall": nix-darwin invokes brew bundle [install] with the --cleanup flag.
      #   - This uninstalls all formulae not listed in generated Brewfile, i.e., brew uninstall is run for those formulae.
      # - "zap": nix-darwin invokes brew bundle [install] with the --cleanup --zap flags.
      #   - This uninstalls all formulae not listed in the generated Brewfile, and if the formula is a cask, removes all files associated with that cask.
      #   - In other words, brew uninstall --zap is run for all those formulae.
      # Do not cleanup, because some formulae are automatically installed by company dev tools.
      cleanup = "none";
    };

    taps = [
      "codingmoh/open-codex"
    ];

    # `brew install`
    # To get the list of installed apps with brew: `brew list`
    brews = [
      # Open-source, extensible AI agent that goes beyond code suggestions - install, execute, edit, and test with any LLM: https://github.com/block/goose
      "block-goose-cli"
      # Elegant Lua unit testing: https://lunarmodules.github.io/busted/
      "busted"
      # Interpreter for PostScript and PDF: https://www.ghostscript.com/
      "ghostscript"
      # Fully open-source command-line AI assistant inspired by OpenAI Codex, supporting local language models: https://github.com/codingmoh/open-codex/
      "open-codex"
    ];

    # `brew install --cask`
    # To get the list of installed apps with brew casks: `brew list --casks`
    casks = [
      # i3-like tiling window manager for macOS: https://github.com/nikitabobko/AeroSpace
      "aerospace"
      # Tools for building Android applications: https://developer.android.com/studio/
      "android-studio"
      # Web security testing toolkit: https://portswigger.net/burp/
      "burp-suite"
      # Web debugging Proxy application: https://www.charlesproxy.com/
      "charles"
      # 👻 Ghostty is a fast, feature-rich, and cross-platform terminal emulator that uses platform-native UI and GPU acceleration: https://ghostty.org/
      "ghostty"
      # Free and open-source image editor: https://www.gimp.org/
      "gimp"
      # Jellyfin is the volunteer-built media solution that puts you in control of your media: https://jellyfin.org/
      #"jellyfin"
      # Free cross-platform office suite, fresh version: https://www.libreoffice.org/
      "libreoffice"
      # Knowledge base that works on top of a local folder of plain text Markdown files: https://obsidian.md/
      "obsidian"
      # Open-source colour picker app for macOS: https://superhighfives.com/pika
      "pika"
      # Music streaming service: https://www.spotify.com/https://www.spotify.com/
      "spotify"
      # macOS system monitor in your menu bar: https://github.com/exelban/stats
      "stats"
      # 🌀 Experience tranquillity while browsing the web without people tracking you: https://zen-browser.app/
      "zen-browser"
    ];
  };
}
