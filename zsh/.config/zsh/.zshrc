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

# plugin management
export ANTIDOTE_HOME="${XDG_CACHE_HOME:=$HOME/.cache}/antidote"
[[ -d "${ANTIDOTE_HOME}/mattmc3/antidote" ]] || git clone --depth 1 --quiet https://github.com/mattmc3/antidote "${ANTIDOTE_HOME}/mattmc3/antidote"
source ${ANTIDOTE_HOME}/mattmc3/antidote/antidote.zsh
antidote load

# vim: ft=zsh
