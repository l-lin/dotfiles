#
# An open source project to pack, ship and run any application as a lightweight container.
# src: https://nixos.wiki/wiki/Docker
#

{
  # https://mynixos.com/nixpkgs/options/virtualisation.docker
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
}
