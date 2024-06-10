#
# Terminal multiplexer
#
# src: https://github.com/tmux/tmux/wiki
#

{ pkgs, ...}: {
  programs.tmux = {
    enable = true;
    # Cannot set the shell directly in the tmux.conf file as the binary is not in /bin folder.
    shell = "${pkgs.zsh}/bin/zsh";
    extraConfig = ''
      ${builtins.readFile ./.tmux.conf}
    '';
  };
}
