#
# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
#
# Exhaustive list of options: https://mynixos.com/home-manager/options
#

{ userSettings, ... }: {
  imports = [
    ./modules/colorscheme.nix
    ./modules/fonts.nix
    ./modules/gui
    ./modules/tui
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
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}
