#
# Open-source, extensible AI agent that goes beyond code suggestions - install, execute, edit, and test with any LLM.
# src: https://github.com/block/goose
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ goose-cli ];
}
