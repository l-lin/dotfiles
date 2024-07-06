#
# Simple and flexible tool for managing secrets.
# src:
# - https://github.com/getsops/sops
# - https://github.com/Mic92/sops-nix
#

{ config, inputs, pkgs, ... }: {
  home.packages = with pkgs; [ sops ];
  imports = with inputs; [ sops-nix.homeManagerModules.sops ];

  sops = {
    age = {
      # This will generate a new key if the key specified below does not exist.
      generateKey = false;
      # This is using an age key that is expected to already be in the filesystem.
      keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      # This will automatically import SSH keys as age keys.
      sshKeyPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];
    };

    defaultSopsFile = ./secrets.yml;
    defaultSymlinkPath = "/run/user/1000/secrets";
    defaultSecretsMountPoint = "/run/user/1000/secrets.d";
  };
}
