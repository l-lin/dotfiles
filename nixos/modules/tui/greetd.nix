#
# Minimalist, agnostic and flexible login manager
# src:
# - https://wiki.archlinux.org/title/Greetd
# - https://github.com/apognu/tuigreet
#

{ pkgs, ... }: {
  services.greetd = {
    enable = true;
    settings = {
      default_session.command = ''
        ${pkgs.greetd.tuigreet}/bin/tuigreet \
        --time \
        --asterisks \
        --user-menu \
        --remember \
        --cmd Hyprland
      '';
    };
  };

  environment.etc."greetd/environments".text = ''
    Hyprland
  '';
}
