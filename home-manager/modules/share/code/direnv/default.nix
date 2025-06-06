#
# A fast, persistent use_nix/use_flake implementation for direnv.
# src: https://github.com/nix-community/nix-direnv
#

# { pkgs, ... }: {
#   programs.direnv = {
#     enable = true;
#     # Whether to enable a faster, persistent implementation of use_nix and use_flake, to replace the built-in one.
#     nix-direnv.enable = true;
#     # Whether to enable silent mode, that is, disabling direnv logging.
#     silent = true;
#   };
#
#   home.packages = with pkgs; [
#     (writeShellScriptBin "nixify" ''
#       ${builtins.readFile ./scripts/nixify.sh}
#     '')
#     (writeShellScriptBin "flakify" ''
#       ${builtins.readFile ./scripts/flakify.sh}
#     '')
#   ];
#
#   # Symlink ~/.config/zsh/plugins/direnv
#   xdg.configFile."zsh/plugins/direnv" = {
#     source = ./.config/zsh/plugins/direnv;
#     recursive = true;
#   };
# }

# Using mise instead, which is has a better DX.
# direnv needs to add the flake.nix to be in git stage area...
{}
