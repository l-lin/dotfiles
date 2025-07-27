#!/usr/bin/env zsh
#
# Content of the command: eval "$(mise activate zsh)"
# `eval` is quite slow. Instead, we can just copy the content to improve the prompt performance.
# src: https://www.dribin.org/dave/blog/archives/2024/01/01/zsh-performance/
#

if ! type mise >/dev/null 2>&1; then return; fi
if [ -n "$__MISE_ACTIVATED" ]; then return; fi

export MISE_SHELL=zsh
export __MISE_ORIG_PATH="$PATH"
export __MISE_ACTIVATED=1

# Lazy load mise hook - only activate on first command execution
function _mise_lazy_hook() {
  # Remove this hook after first run
  add-zsh-hook -d precmd _mise_lazy_hook
  add-zsh-hook -d preexec _mise_lazy_hook

  # Activate mise
  eval "$(mise activate zsh --shims)"
}

# Add hooks for lazy loading
autoload -Uz add-zsh-hook
add-zsh-hook precmd _mise_lazy_hook
add-zsh-hook preexec _mise_lazy_hook

export PATH="$HOME/.local/share/mise/shims:$PATH"
