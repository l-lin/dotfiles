#
# Best text editor in the world!
# src: https://neovim.io/
#

{ pkgs, ... }: {
  # https://mynixos.com/nixpkgs/options/programs.neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    # Symlink vi and vim to nvim binary.
    viAlias = true;
    vimAlias = true;

    withRuby = true;
    withNodeJs = true;
    withPython3 = true;
    #extraPackages = with pkgs; [
    #  # Formatters
    #  nixfmt-rfc-style # Nix
    #  black # Python
    #  prettierd # Multi-language
    #  shfmt # Shell
    #  isort # Python
    #  stylua # Lua

    #  # LSP
    #  lua-language-server
    #  nixd
    #  nil

    #  # Tools
    #  cmake
    #  fswatch # File watcher utility, replacing libuv.fs_event for neovim 10.0
    #  fzf
    #  gcc
    #  git
    #  gnumake
    #  nodejs
    #  sqlite
    #  tree-sitter
    #];

    plugins = [
      # All other plugins are managed by lazy-nvim
      pkgs.vimPlugins.lazy-nvim
    ];
  };

  # Symlink ~/.config/nvim
  xdg.configFile.nvim = {
    source = ./config/nvim;
    recursive = true;
  };

  # Symlink ~/.local/share/eclipse/java-code-style.xml
  home.file.".local/share/eclipse/java-code-style.xml".source = ./config/eclipse/java-code-style.xml;
}
