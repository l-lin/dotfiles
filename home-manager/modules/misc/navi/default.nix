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
  xdg.configFile."tmux/plugins/navi/navi.tmux".source = ./.config/tmux/plugins/navi/navi.tmux;
  xdg.configFile."zsh/plugins/navi/navi.plugin.zsh".source = ./.config/zsh/plugins/navi/navi.plugin.zsh;
}
