#
# SSH
#

{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    (writeShellScriptBin "give-ssh-passphrase" ''
      ${builtins.readFile ./scripts/give-ssh-passphrase.sh}
    '')

    (writeShellScriptBin "unlock-ssh-keys" ''
      ${builtins.readFile ./scripts/unlock-ssh-keys.sh}
    '')
  ];

  programs = {
    ssh = {
      enable = true;
      # When enabled, a private key that is used during authentication will be
      # added to ssh-agent if it is running (with confirmation enabled if
      # set to 'confirm'. The argument must be 'no' (the default), 'yes', 'confirm'
      # (optionally followed by a time interval), 'ask' or a time interval (e.g. '1h').
      addKeysToAgent = "yes";
      matchBlocks = {
        "*" = {
          identityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
        };
      };
    };
  };
}
