#
# Some tools to run unpatched binaries on NixOS.
# src:
# - https://nixos.wiki/wiki/Packaging/Binaries
# - https://rootknecht.net/blog/patching-binaries-for-nixos/
# - https://nix.dev/guides/faq#how-to-run-non-nix-executables
# - https://nixos-and-flakes.thiscute.world/best-practices/run-downloaded-binaries-on-nixos
# - https://unix.stackexchange.com/questions/522822/different-methods-to-run-a-non-nixos-executable-on-nixos
# - https://lwn.net/Articles/631631/
# - https://www.reddit.com/r/NixOS/comments/13uc87h/masonnvim_broke_on_nixos/
#

{ pkgs, ... }: {
  # nix-ld is a useful tool for running pre-compiled executables on NixOS without the need for patching or modification.
  # It provides a shim layer that allows users to specify the necessary libraries for each executable and improves the
  # user experience by allowing users to easily run binaries from third-party sources and proprietary software.
  # By including the most common libraries in the NixOS configuration, nix-ld can provide an even more seamless
  # experience for running pre-compiled executables on NixOS.
  # src:
  # - https://github.com/Mic92/nix-ld
  # - https://blog.thalheim.io/2022/12/31/nix-ld-a-clean-solution-for-issues-with-pre-compiled-executables-on-nixos/
  programs.nix-ld = with pkgs; {
    enable = true;
    package = nix-ld-rs;
    # Default: https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/programs/nix-ld.nix#L44-L58
    # More extensive number of libraries here: https://github.com/Mic92/dotfiles/blob/main/nixos/modules/nix-ld.nix
    # Libraries used by steam-run: https://github.com/NixOS/nixpkgs/blob/master/pkgs/games/steam/fhsenv.nix
    libraries = [
      acl
      alsa-lib
      atk
      attr
      bzip2
      cairo
      cups
      curl
      dbus
      expat
      ffmpeg
      fuse3
      glib
      gtk3
      icu
      libdrm
      libssh
      libsodium
      libxkbcommon
      libxml2
      mesa
      nspr
      nss
      openssl
      pango
      stdenv.cc.cc
      systemd
      util-linux
      xorg.libX11
      xorg.libXScrnSaver
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libXtst
      xorg.libxcb
      xorg.libxkbfile
      xorg.libxshmfence
      xz
      zlib
      zstd
    ];
  };

  # Run commands in the same FHS environment that is used for Steam.
  # usage: steam-run <binary> <args...>
  environment.systemPackages = with pkgs; [ steam-run ];
}
