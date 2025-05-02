#
# AI related stuff.
#

{ fileExplorer, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  # Symlink ~/.config/zsh/secrets/.secrets.ai.
  xdg.configFile."zsh/secrets/.secrets.ai".source = ./.config/zsh/secrets/.secrets.ai;
}
