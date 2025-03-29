#
# AI related stuff.
#

{ fileExplorer, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  # Symlink ~/.config/zsh/functions/aider-convention-scraper.
  xdg.configFile."zsh/zprofile.d/.zprofile.ai".source = ./.config/zsh/zprofile.d/.zprofile.ai;
}
