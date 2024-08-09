#
# Simple and flexible tool for managing secrets.
# src:
# - https://github.com/getsops/sops
# - https://github.com/Mic92/sops-nix
#

{ config, inputs, pkgs, userSettings, ... }: {
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
    #     "ssh-to-age -private-key -i ~/.ssh/l-lin > ~/.config/sops/age/l-lin.age"
    # ```
    keyFile = "${config.home.homeDirectory}/.config/sops/age/${userSettings.username}.age";
  };
}
