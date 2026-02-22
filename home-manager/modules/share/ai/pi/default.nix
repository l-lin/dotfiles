#
# AI agent toolkit: coding agent CLI, unified LLM API, TUI & web UI libraries, Slack bot, vLLM pods
# src: https://github.com/badlogic/pi-mono
#

{ config, symlinkRoot, ... }: {
  xdg.configFile."mise/conf.d/pi.toml".source = ./.config/mise/conf.d/pi.toml;

  home.file = {
    # pi may edit the settings.json, so let allow write on this file.
    ".pi/agent/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${symlinkRoot}/home-manager/modules/share/ai/pi/.pi/agent/settings.json";

    ".pi/agent/keybindings.json".source = ./.pi/agent/keybindings.json;
    ".pi/agent/APPEND_SYSTEM.md".source = ../.config/ai/system-prompt.md;
    ".pi/agent/extensions" = {
      source = ./.pi/agent/extensions;
      recursive = true;
    };

    #
    # AGENTS
    #
    ".pi/agent/subagents/explore.md".source = ./.pi/agent/subagents/explore.md;
    ".pi/agent/subagents/general-purpose.md".source = ./.pi/agent/subagents/general-purpose.md;
    ".pi/agent/subagents/codebase-analyzer.md".text = ''
---
name: codebase-analyzer
description: Analyzes codebase implementation details. Call the codebase-analyzer agent when you need to find detailed information about specific components. As always, the more detailed your request prompt, the better! :)
tools: read, grep, ls, find, bash
---

${builtins.readFile ../.config/ai/agents/codebase-analyzer.md}
    '';
    ".pi/agent/subagents/codebase-locator.md".text = ''
---
name: codebase-locator
description: Locates files, directories, and components relevant to a feature or task. Call `codebase-locator` with human language prompt describing what you're looking for. Basically a "Super Grep/Glob/LS tool" — Use it if you find yourself desiring to use one of these tools more than once.
tools: read, grep, ls, find, bash
---

${builtins.readFile ../.config/ai/agents/codebase-locator.md}
    '';
    ".pi/agent/subagents/codebase-pattern-finder.md".text = ''
---
name: codebase-pattern-finder
description: codebase-pattern-finder is a useful subagent_type for finding similar implementations, usage examples, or existing patterns that can be modeled after. It will give you concrete code examples based on what you're looking for! It's sorta like codebase-locator, but it will not only tell you the location of files, it will also give you code details!
tools: read, grep, ls, find, bash
---

${builtins.readFile ../.config/ai/agents/codebase-pattern-finder.md}
    '';
    ".pi/agent/subagents/git-investigator.md".text = ''
---
name: git-investigator
description: Investigates git history, logs, changes, and uncommitted modifications. Call the git-investigator agent when you need to analyze version control information, track changes over time, or understand the development history of specific components.
tools: read, grep, ls, find, bash
---

${builtins.readFile ../.config/ai/agents/git-investigator.md}
    '';
    ".pi/agent/subagents/web-search-researcher.md".text = ''
---
name: web-search-researcher
description: Do you find yourself desiring information that you don't quite feel well-trained (confident) on? Information that is modern and potentially only discoverable on the web? Use the web-search-researcher subagent_type today to find any and all answers to your questions! It will research deeply to figure out and attempt to answer your questions! If you aren't immediately satisfied you can get your money back! (Not really - but you can re-run web-search-researcher with an altered prompt in the event you're not satisfied the first time)
---

${builtins.readFile ../.config/ai/agents/web-search-researcher.md}
    '';
    ".pi/agent/subagents/ruby-mentor.md".text = ''
---
name: ruby-mentor
description: Ruby Programming Mentor and Best Practices Guide. Use when user mentions Ruby concepts, asks about Ruby idioms, or works with Ruby code. Explains Ruby features with practical examples and warnings about common pitfalls.
tools: read, grep, ls, find, bash
---

${builtins.readFile ../.config/ai/agents/ruby-mentor.md}
    '';
    ".pi/agent/subagents/rails-mentor.md".text = ''
---
name: rails-mentor
description: Rails Framework Mentor and Best Practices Guide. Use when user mentions Rails concepts, asks about Rails patterns, or works with Rails applications. Explains Rails conventions, architecture patterns, and common pitfalls with practical examples.
tools: read, grep, ls, find, bash
---

${builtins.readFile ../.config/ai/agents/rails-mentor.md}
    '';
    ".pi/agent/subagents/kotlin-mentor.md".text = ''
---
name: kotlin-mentor
description: Kotlin Programming Mentor and Best Practices Guide. Use when user mentions Kotlin concepts, asks about Kotlin idioms, or works with Kotlin code. Explains Kotlin features with practical examples and warnings about common pitfalls.
tools: read, grep, ls, find, bash
---

${builtins.readFile ../.config/ai/agents/kotlin-mentor.md}
    '';
  };
}
