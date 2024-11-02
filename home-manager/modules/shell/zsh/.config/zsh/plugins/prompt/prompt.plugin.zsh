#!/usr/bin/env zsh
#
# Set prompt.
#
# src:
# - https://github.com/mattmc3/zdotdir/blob/fd781dc4005110b0ae82f596e205fd020f5657a8/.zshrc#L61-L66
# - https://github.com/mattmc3/zephyr/issues/13
#

# Set prompt theme
typeset -ga ZSH_THEME
zstyle -a ':zephyr:plugin:prompt' theme ZSH_THEME ||
ZSH_THEME=(p10k lean)

# Manually set your prompt ask powerlevel10k may not work well with post_zshrc.
setopt prompt_subst transient_rprompt
autoload -Uz promptinit && promptinit
prompt "$ZSH_THEME[@]"
