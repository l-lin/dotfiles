# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
#
# Exhaustive list of options: https://mynixos.com/home-manager/options
{
  inputs,
  lib,
  config,
  pkgs,
  userSettings,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # TUI
    ./modules/tui/xdg.nix
    ./modules/tui/tmux/tmux.nix
    (./. + "/modules/tui/shell"+("/"+userSettings.shell))

    # GUI
    (./. + "/modules/gui"+("/"+userSettings.wmType+"/"+userSettings.wm)+".nix")
  ];

  home = {
    username = userSettings.username;
    homeDirectory = "/home/"+userSettings.username;
  };

  # TODO: move to their own .nix files
  # Add stuff for your user as you see fit:
  home.packages = with pkgs; [
    # TUI
    bat
    curl
    fd
    fzf
    git
    lsd
    gnumake
    ripgrep
    stow
    wget
    zsh

    # fonts
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # Enable programs
  # NOTE: What's the difference with `home.packages`?
  programs.home-manager.enable = true;
  programs.git.enable = true;
  programs.neovim.enable = true;
  programs.alacritty.enable = true;


  home.sessionVariables = {
    EDITOR = userSettings.editor;
    TERM = userSettings.term;
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}
