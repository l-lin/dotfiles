{ pkgs, ... }: {
  home.packages = with pkgs; [ neovim ];

  # Symlink ~/.config/nvim
  xdg.configFile.nvim = {
    source = ./config;
    recursive = true;
  };
}
