#
# sensible default set by zephyr
# src: https://github.com/mattmc3/zephyr/blob/main/plugins/environment/environment.plugin.zsh
#

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

# vim: ft=zsh
