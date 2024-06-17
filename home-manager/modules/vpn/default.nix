#
# Virtual Private Network.
#

{ outputs, pkgs, systemSettings, ... }: {
  home.packages = with pkgs; [
    # Client for PPP+SSL VPN tunnel services: https://github.com/adrienverge/openfortivpn
    openfortivpn

    outputs.packages.${systemSettings.system}.openfortivpn-webview
  ];
}
