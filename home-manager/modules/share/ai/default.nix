#
# AI related stuff.
#

{ fileExplorer, pkgs, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # Code repository indexing tool to supercharge your LLM experience: https://github.com/Davidyz/VectorCode
    vectorcode
  ];

  # Symlink ~/.config/zsh/functions/aider-convention-scraper.
  xdg.configFile."zsh/zprofile.d/.zprofile.ai".source = ./.config/zsh/zprofile.d/.zprofile.ai;
}
