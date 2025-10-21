#
# An agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster
# src: https://github.com/anthropics/claude-code
#

{
  xdg.configFile."mise/conf.d/claude-code.toml".source = ./.config/mise/conf.d/claude-code.toml;
  xdg.configFile."zsh/functions/ask".source = ./.config/zsh/functions/ask;

  home.file.".claude/settings.json".source = ./.claude/settings.json;
  home.file.".claude/cc_statusline.rb".source = ./.claude/cc_statusline.rb;
  home.file.".claude/mcp" = {
    source = ./.claude/mcp;
    recursive = true;
  };
  home.file.".claude/commands" = {
    source = ../.config/ai/prompts;
    recursive = true;
  };
  home.file.".claude/agents" = {
    source = ../.config/ai/agents;
    recursive = true;
  };
}
