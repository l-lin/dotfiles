{ pkgs, ... }: {
  home.packages = with pkgs; [ git git-lfs ];

  # Symlink to ~/.gitconfig
  home.file.".gitconfig".source = ./config/.gitconfig;
  # Symlink to ~/.config/git/ignore
  xdg.configFile."git/ignore".source = ./config/ignore;
  # Symlink to ~/perso/.gitconfig
  home.file."perso/.gitconfig".source = ./config/.gitconfig_perso;
}
