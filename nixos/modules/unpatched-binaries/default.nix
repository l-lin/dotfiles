#
# Some tools to run unpatched binaries on NixOS.
# For non-proprietary binaries, we should package it the Nix way.
# However, let's be pragmatic, it's much much more complicated and too much hassle than
# just running the binary like any other FHS OS.
# Yes, I'm not entirely adhering to the Nix philosophy... but that's ok, I will survive!
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

  environment.systemPackages = with pkgs; [
    # Small utility to modify the dynamic linker and RPATH of ELF executable.
    #
    # In computing, the Executable and Linkable Format (ELF, formerly named
    # Extensible Linking Format), is a common standard file format for executable
    # files, object code, shared libraries, and core dumps.
    #
    # Moreover, the ELF format is versatile. Its design allows it to be executed
    # on various processor types. This is a significant reason why the format is
    # common compared to other executable file formats.
    #
    # Generally, we write most programs in high-level languages such as C or C++.
    # These programs cannot be directly executed on the CPU because the CPU doesn't
    # understand these instructions. Instead, we use a compiler that compiles the
    # high-level language into object code. Using a linker, we also link the object
    # code with shared libraries to get a binary file.
    #
    # As a result, the binary file has instructions that the CPU can understand and
    # execute. The binary file can adopt any format that defines the structure it
    # should follow. However, the most common of these structures is the ELF format.
    # src:
    # - https://nixos.wiki/wiki/Packaging/Binaries
    # - https://rootknecht.net/blog/patching-binaries-for-nixos/
    # - https://github.com/NixOS/patchelf
    # usage:
    # - patch interpreter
    # patchelf --set-interpreter $(patchelf --print-interpreter `which find`) <binary>
    # - patch rpath
    # patchelf --set-rpath "$(nix eval 'nixpkgs#<lib1>.outPath' --raw)/lib:$(nix eval 'nixpkgs#<lib2>.outPath' --raw)/lib" <binary>
    #patchelf

    # Run commands in the same FHS environment that is used for Steam.
    # usage: steam-run <binary> <args...>
    #steam-run
  ];

}
