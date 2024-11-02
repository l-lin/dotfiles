#
# .zshrc - Run on interactive Zsh session.
#

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# zstyles
[[ -r $ZDOTDIR/.zstyles ]] && . $ZDOTDIR/.zstyles

# zsh custom folder
export ZSH_CUSTOM=${ZDOTDIR:-$HOME/.config/zsh}

# plugin management
export ANTIDOTE_HOME="${XDG_CACHE_HOME:=$HOME/.cache}/antidote"
[[ -d "${ANTIDOTE_HOME}/mattmc3/antidote" ]] || git clone --depth 1 --quiet https://github.com/mattmc3/antidote "${ANTIDOTE_HOME}/mattmc3/antidote"
source ${ANTIDOTE_HOME}/mattmc3/antidote/antidote.zsh
antidote load

# Set prompt theme
typeset -ga ZSH_THEME
zstyle -a ':zephyr:plugin:prompt' theme ZSH_THEME ||
ZSH_THEME=(p10k lean)

# Manually set your prompt ask powerlevel10k may not work well with post_zshrc.
setopt prompt_subst transient_rprompt
autoload -Uz promptinit && promptinit
prompt "$ZSH_THEME[@]"

# vim: ft=zsh
