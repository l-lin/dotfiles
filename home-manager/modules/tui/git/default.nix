{ pkgs, ... }: {
  home.packages = with pkgs; [ git git-lfs ];

  # Symlink to ~/.gitconfig
  home.file.".gitconfig".source = ./config/.gitconfig;
  # Symlink to ~/.gitignore_global
  home.file.".gitignore_global".source = ./config/.gitignore_global;
  # Symlink to ~/perso/.gitconfig
  home.file."perso/.gitconfig".source = ./config/.gitconfig_perso;
}
