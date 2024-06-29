#
# Simple terminal UI for git commands.
# src: https://github.com/jesseduffield/lazygit
#

{ config, pkgs, ... }: {
  home.packages = with pkgs; [ lazygit ];

  # Symlink to ~/.config/lazygit/config.yml
  xdg.configFile."lazygit/config.yml".text = ''
# https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
gui:
  border: "rounded"
  showBottomLine: false
  showRandomTip: false
  nerdFontsVersion: "3"
git:
  mainBranches: [master, main, develop]
  paging:
    colorArg: always
    pager: delta --${config.theme.polarity} --paging=never
keybinding:
  universal:
    prevPage: "<c-u>"
    nextPage: "<c-d>"
    gotoTop: "g"
    gotoBottom: "G"
  '';
}
