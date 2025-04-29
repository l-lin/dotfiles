#
# AI related stuff.
#

{ fileExplorer, pkgs, ... }: {
  imports = fileExplorer.allSubdirs ./.;

  home.packages = with pkgs; [
    # Code repository indexing tool to supercharge your LLM experience: https://github.com/Davidyz/VectorCode
    vectorcode
  ];

  # Symlink ~/.config/zsh/secrets/.secrets.ai.
  xdg.configFile."zsh/secrets/.secrets.ai".source = ./.config/zsh/secrets/.secrets.ai;
}
