#
# .zshrc - Run on interactive Zsh session.
#

# zstyles
[[ -r $ZDOTDIR/.zstyles ]] && . $ZDOTDIR/.zstyles

# zsh custom folder
export ZSH_CUSTOM=${ZDOTDIR:-$HOME/.config/zsh}

# plugin management
export ANTIDOTE_HOME="${XDG_CACHE_HOME:=$HOME/.cache}/antidote"
[[ -d "${ANTIDOTE_HOME}/mattmc3/antidote" ]] || git clone --depth 1 --quiet https://github.com/mattmc3/antidote "${ANTIDOTE_HOME}/mattmc3/antidote"
source ${ANTIDOTE_HOME}/mattmc3/antidote/antidote.zsh
antidote load

# vim: ft=zsh
