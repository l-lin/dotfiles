{ pkgs, ... }: {
  # Middleware mechanism that allows communication betweeen multiple processes.
  services.dbus = {
    enable = true;
    packages = [ pkgs.dconf ];
  };

  programs.dconf = {
    enable = true;
  };
}
