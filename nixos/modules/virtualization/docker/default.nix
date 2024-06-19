#
# An open source project to pack, ship and run any application as a lightweight container.
# src: https://nixos.wiki/wiki/Docker
#

{
  # Docker in rootless mode.
  #
  # Rootless mode is recommended, however there are some limitations.
  # We are using something called `cgroups` which is a Linux kernel feature that limits, accounts
  # for, and isolates the resource usage of a collection of processes.
  # By default, a non-root user can only get memory controller and pids controller to be delegated.
  # So for rootless containers to run properly, we also need to enable CPU, CPUSET, and I/O delegation.
  #
  # src:
  # - https://rootlesscontaine.rs/getting-started/common/cgroup2/#enabling-cpu-cpuset-and-io-delegation
  # - https://github.com/k3d-io/k3d/issues/493
  # - https://mynixos.com/nixpkgs/options/virtualisation.docker
  #virtualisation.docker.rootless = {
  #  enable = true;
  #  setSocketVariable = true;
  #};

  # To use the legacy cgroupsv1, if some application requires it, disable the unified cgroup hierarchy like this.
  # You may need to reboot your system after that.
  #systemd.enableUnifiedCgroupHierarchy = false;

  # Docker in root mode.
  # Because I don't know how to enable CPU delegation to rootless docker...
  # options: https://mynixos.com/nixpkgs/options/virtualisation.docker
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "daily";
    };
  };
}
