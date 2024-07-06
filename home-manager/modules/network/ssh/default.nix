#
# SSH
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    (writeShellScriptBin "give-ssh-passphrase" ''
      ${builtins.readFile ./scripts/give-ssh-passphrase.sh}
    '')

    (writeShellScriptBin "unlock-ssh-keys" ''
      ${builtins.readFile ./scripts/unlock-ssh-keys.sh}
    '')
  ];
}
