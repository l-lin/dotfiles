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

{ inputs, systemSettings, ... }: {
  # Run unpatched binaries on Nix/NixOS as nix-alien will download necessary dependencies for you.
  # src: https://github.com/thiagokokada/nix-alien
  # usage: nix-alien <binary> <args...>
  home.packages = with inputs.nix-alien.packages.${systemSettings.system}; [ nix-alien ];

  # Quickly locate nix packages with specific files: https://github.com/nix-community/nix-index
  # usage: nix-locate --minimal --top-level -w lib/libgobject-2.0.so.0
  programs.nix-index.enable = true;
}
