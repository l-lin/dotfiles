#
# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
#
# Exhaustive list of options: https://mynixos.com/home-manager/options
#

{ userSettings, ... }: {
  imports = [
    ./modules/audio
    ./modules/browser
    ./modules/code
    ./modules/colorscheme.nix
    ./modules/gui
    ./modules/messaging
    ./modules/notification
    ./modules/tui
    ./modules/video
  ];

  home = {
    username = userSettings.username;
    homeDirectory = "/home/"+userSettings.username;
  };

  # Enable home-manager
  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = userSettings.editor;
    TERM = userSettings.term;
    BROWSER = userSettings.browser;
    PAGER = userSettings.pager;
  };

  nixpkgs = {
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}
