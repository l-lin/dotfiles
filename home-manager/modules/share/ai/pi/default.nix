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
      source = config.lib.file.mkOutOfStoreSymlink "${symlinkRoot}/home-manager/modules/share/ai/pi/.pi/agent/extensions";
      recursive = true;
    };

    #
    # AGENTS
    #
    ".pi/agent/subagents/general-purpose.md".source = ./.pi/agent/subagents/general-purpose.md;
    ".pi/agent/subagents/executor.md".source = ./.pi/agent/subagents/executor.md;
    ".pi/agent/subagents/codebase-analyzer.md".text = ''
---
name: codebase-analyzer
description: Use when you need implementation details about specific components, functions, or modules in the codebase
tools: read, grep, ls, find, bash
model: github-copilot/gpt-4.1
---

${builtins.readFile ../.config/ai/agents/codebase-analyzer.md}
    '';
    ".pi/agent/subagents/codebase-locator.md".text = ''
---
name: codebase-locator
description: Use when you need to find files, directories, or components by feature or purpose rather than exact name
tools: read, grep, ls, find, bash
model: github-copilot/gpt-4.1
---

${builtins.readFile ../.config/ai/agents/codebase-locator.md}
    '';
    ".pi/agent/subagents/codebase-pattern-finder.md".text = ''
---
name: codebase-pattern-finder
description: Use when you need existing code examples or patterns to model new implementation after, and want concrete code snippets not just file locations
tools: read, grep, ls, find, bash
model: github-copilot/gpt-4.1
---

${builtins.readFile ../.config/ai/agents/codebase-pattern-finder.md}
    '';
    ".pi/agent/subagents/git-investigator.md".text = ''
---
name: git-investigator
description: Use when you need to analyze git history, track changes over time, or understand the development history of specific files or components
tools: read, grep, ls, find, bash
model: github-copilot/gpt-4.1
---

${builtins.readFile ../.config/ai/agents/git-investigator.md}
    '';
    ".pi/agent/subagents/web-search-researcher.md".text = ''
---
name: web-search-researcher
description: Use when you need current information from the web, facts that may be outdated in training data, or research across multiple online sources
model: github-copilot/gpt-4.1
---

${builtins.readFile ../.config/ai/agents/web-search-researcher.md}
    '';
  };
}
