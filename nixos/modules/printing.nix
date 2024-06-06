#
# Printing in NixOS is done via the services.printing module, to configure the
# local printing services which is provided by the software CUPS.
# Setting up physical printer devices is done using hardware.printers option.
#
# src: https://nixos.wiki/wiki/Printing
#

{ ... }: {
  # Enable CUPS to print documents.
  services.printing.enable = true;
}
