{ ... }: {
  services = {
    qemuGuest.enable = true;
    # Enhanced SPICE integration for linux QEMU guest
    # Spice agent for linux guests offering
    # - Client mouse mode
    # - Copy and paste
    # - Automatic adjustment of the X-session resolution to the client resolution
    # - Multiple displays
    spice-vdagentd.enable = true;
  };
}
