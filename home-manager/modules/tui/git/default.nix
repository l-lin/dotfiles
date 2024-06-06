{ pkgs, ... }: {
  home.packages = with pkgs; [ git ];

  home.file.".gitconfig".source = ./config/.gitconfig;
  home.file.".gitignore_global".source = ./config/.gitignore_global;
}
