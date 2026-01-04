#
# Git is a free and open source distributed version control system designed to handle
# everything from small to very large projects with speed and efficiency.
# src: https://git-scm.com/
#

{ config, pkgs, symlinkRoot, userSettings, ... }: {
  home.packages = with pkgs; [
    # GitHub CLI tool: https://cli.github.com/
    gh
    git
    git-lfs
  ];
  xdg.configFile = {
    # Symlink to ~/.config/git
    "git/ignore".source = ./.config/git/ignore;
    "git/hooks" = {
      source = ./.config/git/hooks;
      recursive = true;
    };
    "git/core".text = ''
  [core]
    editor = ${userSettings.editor}
    autocrlf = input
    pager = delta --${config.theme.polarity}
    hooksPath = ${config.xdg.configHome}/git/hooks
    '';

    "zsh/functions/git-functions" = {
      source = ./.config/zsh/functions/git-functions;
      recursive = true;
    };
  };

  # mkOutOfStoreSymlink creates a mutable symlink (writable at runtime).
  # .gitconfig may be modified by git commands or tools.
  home.file.".gitconfig".source = config.lib.file.mkOutOfStoreSymlink "${symlinkRoot}/home-manager/modules/share/vcs/git/.gitconfig";

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
