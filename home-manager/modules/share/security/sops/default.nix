#
# Simple and flexible tool for managing secrets.
# src:
# - https://github.com/getsops/sops
# - https://github.com/Mic92/sops-nix
#

{ config, inputs, lib, pkgs, ... }:
let
  inherit (pkgs.stdenv) isDarwin;
  # When decrypting a file with the corresponding identity, SOPS will look for a text file name keys.txt
  # located in a sops subdirectory of your user configuration directory.
  # On Linux, this would be $XDG_CONFIG_HOME/sops/age/keys.
  # If $XDG_CONFIG_HOME is not set $HOME/.config/sops/age/keys.txt is used instead.
  # On macOS, this would be $HOME/Library/Application Support/sops/age/keys.txt.
  #
  # src: https://github.com/getsops/sops?tab=readme-ov-file#encrypting-using-age
  sopsKeyFile = if isDarwin then
    "${config.home.homeDirectory}/Library/Application\ Support/sops/age/keys.txt"
  else
    "${config.xdg.configHome}/sops/age/keys.txt";
in {
  # Install SOPS CLI.
  home.packages = with pkgs; [ sops ];
  # Install sops-nix.
  imports = with inputs; [ sops-nix.homeManagerModules.sops ];

  sops.age = {
    # This will generate a new key if the key specified below does not exist.
    generateKey = false;
    # This is using an age key that is expected to already be in the filesystem.
    # Generated using from [ssh-to-age](https://github.com/Mic92/ssh-to-age) on the SSH key `~/.ssh/l-lin`:
    #
    # ```bash
    # SSH_TO_AGE_PASSPHRASE="$(\
    #     bw list items --search ssh@l-lin \
    #     | jq -r '.[].fields[].value'\
    #   )" \
    #   nix-shell -p ssh-to-age --run \
    #     "ssh-to-age -private-key -i ~/.ssh/l-lin >> ~/.config/sops/age/keys.txt"
    # ```
    keyFile = sopsKeyFile;
  };

  # Workaround for sops-nix LaunchAgent empty PATH on macOS.
  # The LaunchAgent's PATH is empty when no age plugins are configured,
  # causing getconf to not be found.
  # src: https://github.com/Mic92/sops-nix/issues/890
  launchd.agents.sops-nix = lib.mkIf isDarwin {
    config.EnvironmentVariables.PATH = lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin";
  };
}
