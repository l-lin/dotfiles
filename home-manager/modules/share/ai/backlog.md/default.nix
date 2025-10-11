#
# A tool for managing project collaboration between humans and AI Agents in a git ecosystem.
# src: https://github.com/MrLesk/Backlog.md
#

{
  # Content extracted directly from the generate output of `backlog init`.
  xdg.configFile."mise/conf.d/backlog.md.toml".source = ./.config/mise/conf.d/backlog.md.toml;
  # Instead of updating CLAUDE.md / AGENTS.md, polluting the context for no reason, I want
  # to explicitely use backlog by using a slash command.
  home.file.".claude/commands/backlog.md".source = ./.config/ai/prompts/backlog.md;
}
