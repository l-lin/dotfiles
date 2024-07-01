#
# Kubernetes is an open-source container orchestration system for automating software deployment, scaling, and management.
# src: https://kubernetes.io/
#

{ fileExplorer, pkgs, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # A helper to run k3s (Lightweight Kubernetes. 5 less than k8s) in a docker container: https://github.com/k3d-io/k3d/
    k3d

    # Kubernetes CLI To Manage Your Clusters In Style: https://github.com/derailed/k9s
    k9s
    # Kubernetes CLI: https://github.com/kubernetes/kubectl
    kubectl
    # Colorizes kubectl output: https://github.com/kubecolor/kubecolor
    kubecolor
    # Faster way to switch between clusters and namespaces in kubectl: https://github.com/ahmetb/kubectx
    kubectx
    # The Kubernetes IDE: https://k8slens.dev/
    lens
  ];
}
