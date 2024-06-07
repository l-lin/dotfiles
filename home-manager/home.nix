#
# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
#
# Exhaustive list of options: https://mynixos.com/home-manager/options
#

{ inputs, lib, config, pkgs, userSettings, ... }: {
  # You can import other home-manager modules here
  imports = [
    ./modules/fonts.nix

    # TUI
    (./. + "/modules/tui/shell"+("/"+userSettings.shell))
    ./modules/tui/alacritty
    ./modules/tui/bat.nix
    ./modules/tui/cli.nix
    ./modules/tui/fzf
    ./modules/tui/git
    ./modules/tui/lazygit
    ./modules/tui/nvim
    ./modules/tui/psql
    ./modules/tui/tmux
    ./modules/tui/xdg.nix

    # GUI
    (./. + "/modules/gui/wm"+("/"+userSettings.wm))
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
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}
