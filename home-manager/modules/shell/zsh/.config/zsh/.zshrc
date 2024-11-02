#
# .zshrc - Run on interactive Zsh session.
#

# zstyles
[[ -r ${ZDOTDIR}/.zstyles ]] && source ${ZDOTDIR}/.zstyles

# plugin management
[[ -r ${ZDOTDIR}/plugins/antidote.zsh ]] && source ${ZDOTDIR}/plugins/antidote.zsh

# vim: ft=zsh
