#
# A package manager for Kubernetes.
# src: https://github.com/kubernetes/helm
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ kubernetes-helm ];

  # Symlink ~/.config/zsh/completions/
  xdg.configFile."zsh/completions/_helm".source = ./config/zsh/completions/_helm;
}
