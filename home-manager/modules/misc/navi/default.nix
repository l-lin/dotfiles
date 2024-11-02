#
# Interactive cheatsheet tool for the command line and application launchers.
# src: https://github.com/denisidoro/navi
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ navi ];

  home.sessionVariables = {
    NAVI_FZF_OVERRIDES_VAR = "--preview-window top:50%:wrap:border";
  };

  # Symlinks
  xdg.configFile."navi/config.yaml".source = ./.config/navi/config.yaml;
  xdg.configFile."zsh/plugins/navi" = {
    source = ./.config/zsh/plugins/navi;
    recursive = true;
  };
}
