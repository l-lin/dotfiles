#
# A tool for managing project collaboration between humans and AI Agents in a git ecosystem.
# src: https://github.com/MrLesk/Backlog.md
#

{
  # Content extracted directly from the generate output of `backlog init`.
  xdg.configFile."mise/conf.d/backlog.md.toml".source = ./.config/mise/conf.d/backlog.md.toml;
  # Instead of updating CLAUDE.md / AGENTS.md, polluting the context for no reason, I want
  # to explicitely use backlog by using claude skills.
  home.file = {
    ".claude/skills/backlog-create" = {
      source = ./.config/ai/skills/backlog-create;
      recursive = true;
    };
    ".claude/skills/backlog-implement" = {
      source = ./.config/ai/skills/backlog-implement;
      recursive = true;
    };
    ".claude/skills/backlog-search" = {
      source = ./.config/ai/skills/backlog-search;
      recursive = true;
    };
  };
}
