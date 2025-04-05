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
    ];

    # `brew install`
    brews = [
      # "wget" # download tool
      # "curl" # no not install curl via nixpkgs, it's not working well on macOS!
      # "aria2" # download tool
      # "httpie" # http client
    ];

    # `brew install --cask`
    casks = [
      # "firefox"
      # "google-chrome"
      # "visual-studio-code"
      #
      # # IM & audio & remote desktop & meeting
      # "telegram"
      # "discord"
      #
      # "anki"
      # "iina" # video player
      # "raycast" # (HotKey: alt/option + space)search, caculate and run scripts(with many plugins)
      # "stats" # beautiful system monitor
      # "eudic" # 欧路词典
      #
      # # Development
      # "insomnia" # REST client
      # "wireshark" # network analyzer
    ];
  };
}
