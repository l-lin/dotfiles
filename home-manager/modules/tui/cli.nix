#
# List of CLI to install that do not need special configuration.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Monitor resources: https://github.com/aristocratos/btop
    btop
    # CLI client for cheat.sh: https://github.com/chubin/cheat.sh
    cht-sh
    # Syntax highlighting for diff: https://www.colordiff.org/
    colordiff
    # Monitor container resources: https://ctop.sh/
    ctop
    # Command line HTTP client: https://curl.se/
    curl
    # User-friendly find: https://github.com/sharkdp/fd
    fd
    # GNU Compiler Collection.
    gcc
    # Add `make` command.
    gnumake
    # CLI to create JSON objects: https://github.com/jpmens/jo
    jo
    # User-friendly command line HTTP client: https://httpie.io/
    httpie
    # Better ls command: https://github.com/lsd-rs/lsd
    lsd
    # Pretty ping: https://github.com/denilsonsa/prettyping
    prettyping
    # Fastest grep in the wild: https://github.com/BurntSushi/ripgrep
    ripgrep
    # Command line tool for retrieving files using HTTP, HTTPS and FTP.
    wget
  ];
}
