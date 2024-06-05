# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
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
    ./modules/tui/tmux/tmux.nix
    #(./. + "../modules/gui/wm"+("/"+userSettings.wmType+"/"+userSettings.wm)+".nix") # Window manager selected from flake
  ];

  home = {
    username = userSettings.username;
    homeDirectory = "/home/"+userSettings.username;
  };

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
  programs.home-manager.enable = true;
  programs.git.enable = true;
  programs.neovim.enable = true;
  programs.alacritty.enable = true;

  # Create XDG Dirs
  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  home.sessionVariables = {
    EDITOR = userSettings.editor;
    TERM = userSettings.term;
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}
