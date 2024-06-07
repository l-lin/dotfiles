#
# /!\ Disable when not in VM!
#

{ ... }: {
  services = {
    # QEMU is a generic and open source machine emulator and virtualizer.
    # src: https://www.qemu.org/
    qemuGuest.enable = true;

    # Enhanced SPICE integration for linux QEMU guest
    # Spice agent for linux guests offering
    # - Client mouse mode
    # - Copy and paste
    # - Automatic adjustment of the X-session resolution to the client resolution
    # - Multiple displays
    # /!\ Not working on Wayland, e.g. clipboard not shared.
    spice-vdagentd.enable = true;
  };
}
