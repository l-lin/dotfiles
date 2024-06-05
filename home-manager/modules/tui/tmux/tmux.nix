{ pkgs, lib, ...}: {
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    extraConfig = ''
      ${builtins.readFile ./tmux.conf}
    '';
  };
}
