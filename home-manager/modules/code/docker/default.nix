#
# An open source project to pack, ship and run any application as a lightweight container.
# src: https://nixos.wiki/wiki/Docker
#

{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Docker CLI plugin to define and run multi-container applications with Docker: https://docs.docker.com/compose/
    docker-compose
    # A simple terminal UI for both docker and docker-compose: https://github.com/jesseduffield/lazydocker
    lazydocker
  ];
}
