#
# PulseAudio is a popular sound server for Linux. It is now required by a number of applications,
# and should be enabled if audio support is desired on NixOS.
# Enabling PulseAudio is sufficient to enable audio support on NixOS in most cases.
# src: https://nixos.wiki/wiki/PulseAudio
#

{ fileExplorer, ... }: {
  imports = fileExplorer.allSubdirs ./.;
}

