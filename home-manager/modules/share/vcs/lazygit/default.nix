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
  # Nerd fonts version to use.
  # One of: '2' | '3' | empty string (default)
  # If empty, do not show icons.
  nerdFontsVersion: "3"
  # If true, display the files in the file views as a tree. If false, display the files as a flat list.
  # This can be toggled from within Lazygit with the '`' key, but that will not change the default.
  showFileTree: false
  # If true, show the number of lines changed per file in the Files view
  showNumstatInFilesView: true
git:
  mainBranches: [master, main, develop]
  pagers:
    - pager: delta --${config.theme.polarity} --paging=never
  # If true, parse emoji strings in commit messages e.g. render :rocket: as 🚀
  # (This should really be under 'gui', not 'git')
  parseEmoji: true
keybinding:
  universal:
    prevPage: "<c-u>"
    nextPage: "<c-d>"
    gotoTop: "g"
    gotoBottom: "G"
  '';
}
