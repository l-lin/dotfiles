#
# Git is a free and open source distributed version control system designed to handle
# everything from small to very large projects with speed and efficiency.
# src: https://git-scm.com/
#

{ pkgs, userSettings, ... }: {
  home.packages = with pkgs; [ git git-lfs ];

  # Symlink to ~/.gitconfig
  home.file.".gitconfig".source = ./config/.gitconfig;
  # Symlink to ~/.config/git/ignore
  xdg.configFile."git/ignore".source = ./config/ignore;
  # Symlink to ~/perso/.gitconfig
  home.file."perso/.gitconfig".text = ''
[user]
  email = ${userSettings.email}
  '';
}
