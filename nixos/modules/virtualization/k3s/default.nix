#
# K3s is a simplified Kubernetes version that bundles Kubernetes cluster components into a few small binaries optimized for Edge and IoT devices.
# You should k3d for local development instead as the latter is installed at user level.
# src: https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/cluster/k3s/docs/USAGE.md
#

{
  networking.firewall = {
    allowedTCPPorts = [
      # k3s: required so that pods can reach the API server (running on port 6443 by default)
      6443
      # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
      #2379
      # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
      #2380
    ];
    allowedUDPPorts = [
      # 8472 # k3s, flannel: required if using multi-node for inter-node networking
    ];
  };
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      # Optionally add additional args to k3s
      #"--kubelet-arg=v=4"
    ];
  };
}
