#
# # Multi pod and container log tailing for Kubernetes.
# src: https://github.com/stern/stern
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ stern ];

  # Symlink ~/.config/zsh/completions/
  xdg.configFile."zsh/completions/_stern".source = ./config/zsh/completions/_stern;
}
