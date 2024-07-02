#
# A fast, persistent use_nix/use_flake implementation for direnv.
# src: https://github.com/nix-community/nix-direnv
#

{ pkgs, ... }: {
  programs = {
    # https://mynixos.com/search?q=direnv
    direnv = {
      enable = true;
      enableZshIntegration = true;
      # Whether to enable a faster, persistent implementation of use_nix and use_flake, to replace the built-in one.
      nix-direnv.enable = true;
    };
  };

  home.packages = with pkgs; [
    (writeShellScriptBin "nixify" ''
      ${builtins.readFile ./scripts/nixify.sh}
    '')
    (writeShellScriptBin "flakify" ''
      ${builtins.readFile ./scripts/flakify.sh}
    '')
  ];
}
