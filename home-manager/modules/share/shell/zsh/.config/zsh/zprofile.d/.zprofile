#
# sensible default set by zephyr
# src: https://github.com/mattmc3/zephyr/blob/main/plugins/environment/environment.plugin.zsh
#

# Source environment variables set by home-manager.
. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
if [[ -z "${__HM_ZSH_SESS_VARS_SOURCED-}" ]]; then
  export __HM_ZSH_SESS_VARS_SOURCED=1
fi

# compinit dump file used for zsh completion
export ZSH_COMPDUMP="${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/.zcompdump"

# --------------------------------------------------------
# zsh vi mode
# --------------------------------------------------------
export ZVM_VI_EDITOR=nvim
export ZVM_KEYTIMEOUT=0.1

# --------------------------------------------------------
# others
# --------------------------------------------------------
export GREP_COLORS='mt=32'
# zephyr plugin is setting the wrong parameter for LESS, which triggers an error when using `bat`:
#
# > Negative number not allowed in -z
#
# src: https://github.com/mattmc3/zephyr/blob/35b5e5618a0147ac037d353e339f35ca5cd9043d/plugins/environment/environment.plugin.zsh#L63
export LESS='-g -i -M -R -S -w -z4'

# vim: ft=zsh
