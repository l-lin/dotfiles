{ ... }: {
  services = {
    qemuGuest.enable = true;
    spice-vdagentd.enable = true;
  };
}
