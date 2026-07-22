#
# src: https://nixos.wiki/wiki/Zsh
#

{
  home.file.".zshenv".source = ./.zshenv;
  xdg.configFile.zsh = {
    source = ./.config/zsh;
    recursive = true;
  };
}
