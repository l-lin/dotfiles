#
# Interactive cheatsheet tool for the command line and application launchers.
# src: https://github.com/denisidoro/navi
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ navi ];

  home.sessionVariables = {
    NAVI_FZF_OVERRIDES_VAR = "--preview-window top:50%:wrap:border";
  };

  # Symlink to ~/.config/navi/config.yaml
  xdg.configFile."navi/config.yaml".source = ./config/config.yaml;
}
