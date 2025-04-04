#
# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
#
# Exhaustive list of options: https://mynixos.com/home-manager/options
#

{ userSettings, systemSettings, ... }:
let
  homeDirectory = if (systemSettings.system == "x86_64-linux") then "/home/" else "/Users/";
  copyCmd = if (systemSettings.system == "x86_64-linux") then "xsel -b" else "pbcopy";
  pasteCmd = if (systemSettings.system == "x86_64-linux") then "xsel -b" else "pbpaste";
in {
  imports = [ ./modules ];

  home = {
    username = userSettings.username;
    homeDirectory = homeDirectory+userSettings.username;
  };

  # Enable home-manager
  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = userSettings.editor;
    VISUAL = userSettings.editor;
    BROWSER = userSettings.browser;
    PAGER = userSettings.pager;
    COPY_TO_CLIPBOARD = copyCmd;
    PASTE_FROM_CLIPBOARD = pasteCmd;

    # No need to not set the `TERM` env variable here.
    # Tmux will fill it automatically with its conf file.
    # Kitty will also do it automatically.
    # If you force the env variable here by setting "kitty" for example, you may
    # have some unexpected behavior, for example, the zsh-vi-mode will display
    # a block instead of a beam in insert mode.
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
  #systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}
