#
# A de-minifier (formatter, exploder, beautifier) for shell one-liners
# src: https://github.com/noperator/sol
#

{ outputs, systemSettings, ... }: {
  home.packages = [ outputs.packages.${systemSettings.system}.sol ];

  # Symlink ~/.config/zsh/plugins/sol/sol.plugin.zsh
  xdg.configFile."zsh/plugins/sol/sol.plugin.zsh".source = ./.config/zsh/plugins/sol/sol.plugin.zsh;
}
