{ pkgs, ... }: {
  home.packages = with pkgs; [ zsh ];

  # Symlink ~/.zshenv
  home.file.".zshenv".source = ./config/.zshenv;
  # Symlink ~/.config/zsh
  xdg.configFile.zsh = {
    source = ./config;
    recursive = true;
  };
}
