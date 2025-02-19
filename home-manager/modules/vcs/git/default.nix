#
# Git is a free and open source distributed version control system designed to handle
# everything from small to very large projects with speed and efficiency.
# src: https://git-scm.com/
#

{ config, pkgs, userSettings, ... }: {
  home.packages = with pkgs; [
    # GitHub CLI tool: https://cli.github.com/
    gh
    git
    git-lfs
  ];

  # Symlink to ~/.gitconfig
  home.file.".gitconfig".source = ./.gitconfig;

  # Symlink to ~/.config/git
  xdg.configFile."git/ignore".source = ./.config/git/ignore;
  xdg.configFile."git/hooks" = {
    source = ./.config/git/hooks;
    recursive = true;
  };
  xdg.configFile."git/core".text = ''
[core]
  editor = ${userSettings.editor}
  autocrlf = input
  pager = delta --${config.theme.polarity}
  hooksPath = ${config.xdg.configHome}/git/hooks
  # accelerate git status on big repo
  fsmonitor = true
  untrackedcache = true
  '';

  # Symlink to ~/perso/.gitconfig
  home.file."perso/.gitconfig".text = ''
[commit]
  # sign commits
  gpgsign = true
[gpg]
  format = ssh
[gpg "ssh"]
  allowedSignersFile = ~/.ssh/allowed_signers
[tag]
  # sign tags
  gpgsign = true
[user]
  email = ${userSettings.email}
  signingkey = ~/.ssh/${userSettings.username}.pub
  '';
}
