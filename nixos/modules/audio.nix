#
# PulseAudio is a popular sound server for Linux. It is now required by a number of applications,
# and should be enabled if audio support is desired on NixOS.
# Enabling PulseAudio is sufficient to enable audio support on NixOS in most cases.
#
# src: https://nixos.wiki/wiki/PulseAudio
#

{
  sound.enable = true;
  nixpkgs.config.pulseaudio = true;
  # Allow bluetooth audio devices to be used with PulseAudio.
  hardware.pulseaudio.enable = false;
}

