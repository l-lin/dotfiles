#
# Other stuff I can't categorize.
#

{ fileExplorer, pkgs, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # Code search-and-replace tool: https://github.com/dalance/amber
    amber
    # Client for cheat.sh: https://github.com/chubin/cheat.sh
    cht-sh
    # Syntax highlighting for diff: https://www.colordiff.org/
    colordiff
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
    # Run arbitrary commands when files change: https://eradman.com/entrproject/
    entr
    # A modern, maintained replacement for ls: https://github.com/eza-community/eza
    eza
    # A tool to read, write and edit EXIF meta information: https://exiftool.org/
    exiftool
    # Wrapper to execute command in a pty: https://github.com/dtolnay/faketty
    faketty
    # User-friendly find: https://github.com/sharkdp/fd
    fd
    # A program that shows the type of files: https://darwinsys.com/file
    file
 
    # Enhance shell: https://github.com/charmbracelet/gum
    gum
    # Benchmarking tool: https://github.com/sharkdp/hyperfine
    hyperfine
    # Decode and encode JWT: https://github.com/mike-engel/jwt-cli
    jwt-cli
    # Kill all processes matching a pattern.
    killall
    # Yet another nix cli helper: https://github.com/viperML/nh
    nh
    # A command-line utility for easily compressing and decompressing files and directories: https://github.com/ouch-org/ouch
    ouch
    # Daemon for managing long running shell commands: https://github.com/Nukesor/pueue
    pueue
    # Pretty ping: https://github.com/denilsonsa/prettyping
    prettyping
    # Modern replacement for top: https://github.com/dalance/procs
    procs
    # Fastest grep in the wild: https://github.com/BurntSushi/ripgrep
    ripgrep
    # Intuitive find & replace: https://github.com/chmln/sd
    sd
    # CLI tool to insert spacers when command output stops: https://github.com/samwho/spacer
    spacer
    # A tool for managing the installation of multiple software packages in the same run-time directory tree: https://www.gnu.org/software/stow/
    stow
    # Command to produce a depth indented directory listing: https://oldmanprogrammer.net/source.php?dir=projects/tree
    tree
    # An extraction utility for archives compressed in .zip format: http://www.info-zip.org/
    unzip
    # Modern watch command: https://github.com/sachaos/viddy
    viddy
    # Command line tool to process CSV files directly from the shell: https://github.com/medialab/xan
    xan
    # Compressor/archiver for creating and modifying zipfiles: http://www.info-zip.org/
    zip
  ];
}
