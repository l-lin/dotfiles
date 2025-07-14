#
# An agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster
# src: https://github.com/anthropics/claude-code
#

{
  xdg.configFile."mise/conf.d/claude-code.toml".source = ./.config/mise/conf.d/claude-code.toml;

  home.file.".claude/CLAUDE.md".source = ../.config/ai/conventions/code.md;
  home.file.".claude/settings.json".source = ./.claude/settings.json;
  home.file.".claude/commands" = {
    source = ../.config/ai/prompts;
    recursive = true;
  };
}
