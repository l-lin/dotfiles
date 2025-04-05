#
# Command-line interface for running Temporal Server and interacting with Workflows,
# Activities, Namespaces, and other parts of Temporal.
# src: https://docs.temporal.io/cli
#

# HACK: DISABLED because I don't need temporal yet.
# { pkgs, ... }: {
#   home.packages = with pkgs; [ temporal-cli ];
#
#   xdg.configFile."zsh/completions/_temporal".source = ./.config/zsh/completions/_temporal;
# }
{}
