#
# An agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster
# src: https://github.com/anthropics/claude-code
#

{
  xdg.configFile = {
    "mise/conf.d/claude-code.toml".source = ./.config/mise/conf.d/claude-code.toml;
    "zsh/functions/ask".source = ./.config/zsh/functions/ask;
  };

  home = {
    sessionVariables = {
      # Enable experimental MCP-CLI for reduced token consumption.
      # https://github.com/anthropics/claude-code/issues/7336#issuecomment-3650620407
      ENABLE_EXPERIMENTAL_MCP_CLI = "true";
    };

    file = {
      ".claude/settings.json".source = ./.claude/settings.json;
      ".claude/cc_statusline.rb".source = ./.claude/cc_statusline.rb;
      ".claude/CLAUDE.md".source = ../.config/ai/conventions/code.md;
      ".claude/mcp" = {
        source = ./.claude/mcp;
        recursive = true;
      };
      ".claude/commands" = {
        source = ../.config/ai/prompts;
        recursive = true;
      };
      ".claude/skills" = {
        source = ../.config/ai/skills;
        recursive = true;
      };

      #
      # AGENTS
      #

      ".claude/agents/codebase-analyzer.md".text = ''
---
name: codebase-analyzer
description: Analyzes codebase implementation details. Call the codebase-analyzer agent when you need to find detailed information about specific components. As always, the more detailed your request prompt, the better! :)
tools: Read, Grep, Glob, LS
model: sonnet
color: orange
---

${builtins.readFile ../.config/ai/agents/codebase-analyzer.md}
      '';
      ".claude/agents/codebase-locator.md".text = ''
---
name: codebase-locator
description: Locates files, directories, and components relevant to a feature or task. Call `codebase-locator` with human language prompt describing what you're looking for. Basically a "Super Grep/Glob/LS tool" — Use it if you find yourself desiring to use one of these tools more than once.
tools: Grep, Glob, LS
model: sonnet
color: orange
---

${builtins.readFile ../.config/ai/agents/codebase-locator.md}
      '';
      ".claude/agents/codebase-pattern-finder.md".text = ''
---
name: codebase-pattern-finder
description: codebase-pattern-finder is a useful subagent_type for finding similar implementations, usage examples, or existing patterns that can be modeled after. It will give you concrete code examples based on what you're looking for! It's sorta like codebase-locator, but it will not only tell you the location of files, it will also give you code details!
tools: Grep, Glob, Read, LS
model: sonnet
color: orange
---

${builtins.readFile ../.config/ai/agents/codebase-pattern-finder.md}
      '';
      ".claude/agents/git-investigator.md".text = ''
---
name: git-investigator
description: Investigates git history, logs, changes, and uncommitted modifications. Call the git-investigator agent when you need to analyze version control information, track changes over time, or understand the development history of specific components.
tools: Read, Grep, Glob, LS
model: inherit
color: orange
---

${builtins.readFile ../.config/ai/agents/git-investigator.md}
      '';
      ".claude/agents/web-search-researcher.md".text = ''
---
name: web-search-researcher
description: Do you find yourself desiring information that you don't quite feel well-trained (confident) on? Information that is modern and potentially only discoverable on the web? Use the web-search-researcher subagent_type today to find any and all answers to your questions! It will research deeply to figure out and attempt to answer your questions! If you aren't immediately satisfied you can get your money back! (Not really - but you can re-run web-search-researcher with an altered prompt in the event you're not satisfied the first time)
tools: WebSearch, WebFetch, TodoWrite, Read, Grep, Glob, LS
model: inherit
color: orange
---

${builtins.readFile ../.config/ai/agents/web-search-researcher.md}
      '';
      ".claude/agents/ruby-mentor.md".text = ''
---
name: ruby-mentor
description: Ruby Programming Mentor and Best Practices Guide. Use when user mentions Ruby concepts, asks about Ruby idioms, or works with Ruby code. Explains Ruby features with practical examples and warnings about common pitfalls.
tools: Read, Grep, Glob, LS
model: inherit
color: purple
---

${builtins.readFile ../.config/ai/agents/ruby-mentor.md}
      '';
      ".claude/agents/rails-mentor.md".text = ''
---
name: rails-mentor
description: Rails Framework Mentor and Best Practices Guide. Use when user mentions Rails concepts, asks about Rails patterns, or works with Rails applications. Explains Rails conventions, architecture patterns, and common pitfalls with practical examples.
tools: Read, Grep, Glob, LS
model: inherit
color: purple
---

${builtins.readFile ../.config/ai/agents/rails-mentor.md}
      '';
    };
  };

}
