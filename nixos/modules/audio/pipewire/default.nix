#
# PipeWire is a new low-level multimedia framework. It aims to offer capture and playback for
# both audio and video with minimal latency and support for PulseAudio-, JACK-, ALSA- and
# GStreamer-based applications.
# PipeWire has a great bluetooth support: because Pulseaudio was reported to have troubles with
# bluetooth, PipeWire can be a good alternative.
# src: https://nixos.wiki/wiki/PipeWire
#

{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;

    # ALSA is the kernel-level sound API for Linux. On modern systems,
    # it is usually used via a sound server like PulseAudio.
    #
    # See https://nixos.wiki/wiki/ALSA
    alsa.enable = true;
    alsa.support32Bit = true;

    # Enable PulseAudio server emulation.
    pulse.enable = true;
    # Enable JACK applications support.
    jack.enable = true;
    # Enable WirePlumber, a modular session / policy manager for PipeWire.
    wireplumber.enable = true;
  };

  # This is only meant for ALSA-based configurations, not for PipeWire.
  sound.enable = false;
  # Use PipeWire instead of PulseAudio.
  hardware.pulseaudio.enable = false;
}

