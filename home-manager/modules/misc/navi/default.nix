#
# Interactive cheatsheet tool for the command line and application launchers.
# src: https://github.com/denisidoro/navi
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ navi ];

  # Symlink to ~/.config/navi/config.yaml
  xdg.configFile."navi/config.yaml".source = ./config.yaml;
}
