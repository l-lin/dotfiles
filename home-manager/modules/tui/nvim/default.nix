{ pkgs, ... }: {
  home.packages = with pkgs; [ neovim ];

  # Symlink ~/.config/nvim
  xdg.configFile.nvim = {
    source = ./config;
    recursive = true;
  };

  # Symlink ~/.local/share/eclipse/java-code-style.xml
  home.file.".local/share/eclipse/java-code-style.xml".source = ./java-code-style.xml;
}
