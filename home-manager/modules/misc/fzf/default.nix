#
# Command-line fuzzy finder.
# src: https://github.com/junegunn/fzf
#

{ pkgs, ... }: {

  home.packages = with pkgs; [
    fzf

    # Register fzf.zsh script as a package so I can call it from anywhere.
    # src: https://discourse.nixos.org/t/link-scripts-to-bin-home-manager/41774/2
    (writeShellScriptBin "fzf.zsh" ''
      ${builtins.readFile ./fzf.zsh}
    '')
  ];
}
