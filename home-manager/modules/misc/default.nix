#
# Other stuff I can't categorize.
#

{ fileExplorer, pkgs, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # Show battery status and other ACPI information: https://sourceforge.net/projects/acpiclient/
    acpi
    # Code search-and-replace tool: https://github.com/dalance/amber
    amber
    # A CLI utility for displaying current network utilization: https://github.com/imsnif/bandwhich
    bandwhich
    # A menu-driven bash script for the management of removable media with udisks: https://github.com/jamielinux/bashmount
    bashmount
    # Read and control device brightness: https://github.com/Hummer12007/brightnessctl
    brightnessctl
    # TUI calendar: https://github.com/anufrievroman/calcure
    calcure
    # Client for cheat.sh: https://github.com/chubin/cheat.sh
    cht-sh
    # Syntax highlighting for diff: https://www.colordiff.org/
    colordiff
    # Monitor container resources: https://ctop.sh/
    ctop
    # HTTP client: https://curl.se/
    curl
    # Scan Nix files for dead code: https://github.com/astro/deadnix
    deadnix
    # Search DuckDuckGo from the terminal: https://github.com/jarun/ddgr
    ddgr
    # Syntax-highlighting for git: https://github.com/dandavison/delta
    delta
    # Disk Usage/Free Utility: https://github.com/muesli/duf/
    duf
    # More intuitive version of du: https://github.com/bootandy/dust
    dust
    # A tool to read, write and edit EXIF meta information: https://exiftool.org/
    exiftool
    # Wrapper to execute command in a pty: https://github.com/dtolnay/faketty
    faketty
    # User-friendly find: https://github.com/sharkdp/fd
    fd
    # A program that shows the type of files: https://darwinsys.com/file
    file
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
    # Tools for reading hardware sensors: https://hwmon.wiki.kernel.org/lm_sensors
    lm_sensors
    # Better ls command: https://github.com/lsd-rs/lsd
    lsd
    # High precision scientific calculator with full support for physical units: https://numbat.dev/
    numbat
    # A command-line utility for easily compressing and decompressing files and directories: https://github.com/ouch-org/ouch
    ouch
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
    # CLI tool to insert spacers when command output stops: https://github.com/samwho/spacer
    spacer
    # A tool for managing the installation of multiple software packages in the same run-time directory tree: https://www.gnu.org/software/stow/
    stow
    # A log file highlighter: https://github.com/bensadeh/tailspin
    tailspin
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
