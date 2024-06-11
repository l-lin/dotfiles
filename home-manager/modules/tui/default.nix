#
# Terminal User Interfaces.
#

{ pkgs, userSettings, ... }: {
  imports = [
    ./audio
    ./atuin
    ./bat.nix
    ./code
    ./direnv
    ./docker
    ./file-manager
    ./fzf
    ./git
    ./lazygit
    ./multiplexer/tmux
    ./navi
    ./nvim
    ./psql
    (./. + "/shell/${userSettings.shell}")
    ./spotify
    ./tealdeer
    ./term
    ./xdg.nix
  ];

  home.packages = with pkgs; [
    # Show battery status and other ACPI information: https://sourceforge.net/projects/acpiclient/
    acpi
    # Code search-and-replace tool: https://github.com/dalance/amber
    amber
    # A menu-driven bash script for the management of removable media with udisks: https://github.com/jamielinux/bashmount
    bashmount
    # Read and control device brightness: https://github.com/Hummer12007/brightnessctl
    brightnessctl
    # Monitor resources: https://github.com/aristocratos/btop
    btop
    # Client for cheat.sh: https://github.com/chubin/cheat.sh
    cht-sh
    # Syntax highlighting for diff: https://www.colordiff.org/
    colordiff
    # Monitor container resources: https://ctop.sh/
    ctop
    # HTTP client: https://curl.se/
    curl
    # Search DuckDuckGo from the terminal: https://github.com/jarun/ddgr
    ddgr
    # Syntax-highlighting for git: https://github.com/dandavison/delta
    delta
    # Disk Usage/Free Utility: https://github.com/muesli/duf/
    duf
    # More intuitive version of du: https://github.com/bootandy/dust
    dust
    # Wrapper to execute command in a pty: https://github.com/dtolnay/faketty
    faketty
    # User-friendly find: https://github.com/sharkdp/fd
    fd
    # A complete, cross-platform solution to record, convert and stream audio and video: https://www.ffmpeg.org/
    ffmpeg
    # A program that shows the type of files: https://darwinsys.com/file
    file
    # GNU Compiler Collection.
    gcc
    # Add `make` command.
    gnumake
    # GNU implementation of the `tar' archiver: https://www.gnu.org/software/tar/
    gnutar
    # Like cURL, but for gRPC: https://github.com/fullstorydev/grpcurl
    grpcurl
    # Enhance shell: https://github.com/charmbracelet/gum
    gum
    # User-friendly command line HTTP client: https://httpie.io/
    httpie
    # A fast and modern static website engine: https://gohugo.io/
    hugo
    # Benchmarking tool: https://github.com/sharkdp/hyperfine
    hyperfine
    # Interactive jq: https://git.sr.ht/~gpanders/ijq
    ijq
    # Pager for JSON data: https://jless.io/
    jless
    # Create JSON objects: https://github.com/jpmens/jo
    jo
    # Lightweight and flexible JSON processor: https://jqlang.github.io/jq/
    jq
    # Decode and encode JWT: https://github.com/mike-engel/jwt-cli
    jwt-cli
    # Kill all processes matching a pattern.
    killall
    # Send desktop notifications: https://gitlab.gnome.org/GNOME/libnotify
    libnotify
    # Better ls command: https://github.com/lsd-rs/lsd
    lsd
    # Stores, retrieves, generates, and synchronizes passwords securely: https://www.passwordstore.org/
    pass-wayland
    # Pretty ping: https://github.com/denilsonsa/prettyping
    prettyping
    # Modern replacement for top: https://github.com/dalance/procs
    procs
    # Fastest grep in the wild: https://github.com/BurntSushi/ripgrep
    ripgrep
    # Intuitive find & replace: https://github.com/chmln/sd
    sd
    # Terminal based presentation tool: https://github.com/maaslalani/slides
    slides
    # A tool for managing the installation of multiple software packages in the same run-time directory tree: https://www.gnu.org/software/stow/
    stow
    # An extraction utility for archives compressed in .zip format: http://www.info-zip.org/
    unzip
    # Modern watch command: https://github.com/sachaos/viddy
    viddy
    # WebSockets client: https://github.com/vi/websocat
    websocat
    # CLI for retrieving files using HTTP, HTTPS and FTP.
    wget
    # CSV toolkit: https://github.com/BurntSushi/xsv
    xsv
    # YAML/XML/TOML processor: https://github.com/kislyuk/yq
    yq
    # Compressor/archiver for creating and modifying zipfiles: http://www.info-zip.org/
    zip
  ];
}
