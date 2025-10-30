#
# The AI coding agent built for the terminal.
# src: https://opencode.ai/
#

{
  xdg = {
    configFile = {
      "mise/conf.d/opencode.toml".source = ./.config/mise/conf.d/opencode.toml;
      "opencode/config.json".source = ./.config/opencode/config.json;
      "opencode/AGENTS.md".source = ../.config/ai/conventions/code.md;
      "opencode/command" = {
        source = ../.config/ai/prompts;
        recursive = true;
      };

      #
      # AGENTS
      #

      "opencode/agent/codebase-analyzer.md".text = ''
---
description: Analyzes codebase implementation details. Call the codebase-analyzer agent when you need to find detailed information about specific components. As always, the more detailed your request prompt, the better! :)
mode: subagent
model: github-copilot/gpt-4.1
temperature: 0
tools:
  read: true
  grep: true
  glob: true
  list: true
---

${builtins.readFile ../.config/ai/agents/codebase-analyzer.md}
      '';
      "opencode/agent/codebase-locator.md".text = ''
---
description: Locates files, directories, and components relevant to a feature or task. Call `codebase-locator` with human language prompt describing what you're looking for. Basically a "Super Grep/Glob/LS tool" — Use it if you find yourself desiring to use one of these tools more than once.
mode: subagent
model: github-copilot/gpt-4.1
temperature: 0
tools:
  grep: true
  glob: true
  list: true
---

${builtins.readFile ../.config/ai/agents/codebase-locator.md}
      '';
      "opencode/agent/codebase-pattern-finder.md".text = ''
---
description: codebase-pattern-finder is a useful subagent_type for finding similar implementations, usage examples, or existing patterns that can be modeled after. It will give you concrete code examples based on what you're looking for! It's sorta like codebase-locator, but it will not only tell you the location of files, it will also give you code details!
mode: subagent
model: github-copilot/gpt-4.1
temperature: 0
tools:
  read: true
  grep: true
  glob: true
  list: true
---

${builtins.readFile ../.config/ai/agents/codebase-pattern-finder.md}
      '';
      "opencode/agent/git-investigator.md".text = ''
---
description: Investigates git history, logs, changes, and uncommitted modifications. Call the git-investigator agent when you need to analyze version control information, track changes over time, or understand the development history of specific components.
mode: subagent
model: github-copilot/gpt-4.1
temperature: 0
tools:
  read: true
  grep: true
  glob: true
  list: true
---

${builtins.readFile ../.config/ai/agents/git-investigator.md}
      '';
      "opencode/agent/web-search-researcher.md".text = ''
---
description: Do you find yourself desiring information that you don't quite feel well-trained (confident) on? Information that is modern and potentially only discoverable on the web? Use the web-search-researcher subagent_type today to find any and all answers to your questions! It will research deeply to figure out and attempt to answer your questions! If you aren't immediately satisfied you can get your money back! (Not really - but you can re-run web-search-researcher with an altered prompt in the event you're not satisfied the first time)
mode: subagent
model: github-copilot/gpt-4.1
temperature: 0
tools:
  read: true
  grep: true
  glob: true
  list: true
  todoread: true
  todowrite: true
  webfetch: true
---

${builtins.readFile ../.config/ai/agents/web-search-researcher.md}
      '';
    };
  };
}
