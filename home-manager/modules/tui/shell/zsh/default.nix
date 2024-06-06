# TODO: migrate from dotfiles to nix
{ ... }: {
  home.file.".zshenv".source = ./config/.zshenv;

  xdg.configFile.zsh = {
    source = ./config;
    recursive = true;
  };
}
