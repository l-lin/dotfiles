#
# A fast, persistent use_nix/use_flake implementation for direnv.
# src: https://github.com/nix-community/nix-direnv
#

{
  programs = {
    # https://mynixos.com/search?q=direnv
    direnv = {
      enable = true;
      enableZshIntegration = true;
      # Whether to enable a faster, persistent implementation of use_nix and use_flake, to replace the built-in one.
      nix-direnv.enable = true;
    };
  };
}
