#
# Virtual Private Network.
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Client for PPP+SSL VPN tunnel services: https://github.com/adrienverge/openfortivpn
    openfortivpn
  ];
}
