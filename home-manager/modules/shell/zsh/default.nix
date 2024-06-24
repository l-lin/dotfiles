#
# src: https://nixos.wiki/wiki/Zsh
#

{
  programs.zsh = {
    enable = true;

    # home-manager is creating its own ~/.zshenv that source the environment variables set by
    # `home.sessionVariables` instructions in the *.nix files:
    #
    # ```sh
    # . "${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh"
    # ```
    #
    # So if I want to add my own `.zshenv` content with the env variables provided by home-manager,
    # we can append with the following:
    envExtra = builtins.readFile ./config/.zshenv;
  };

  # Symlink ~/.config/zsh
  xdg.configFile.zsh = {
    source = ./config;
    recursive = true;
  };
}
