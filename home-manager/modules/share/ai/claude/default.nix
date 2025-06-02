#
# An agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster
# src: https://github.com/anthropics/claude-code
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ claude-code ];

  home.sessionVariables = {
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
  };
}
