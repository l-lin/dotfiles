#
# sensible default set by zephyr
# src: https://github.com/mattmc3/zephyr/blob/main/plugins/environment/environment.plugin.zsh
#

# compinit dump file used for zsh completion
export ZSH_COMPDUMP="${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/.zcompdump"

# --------------------------------------------------------
# zsh-autoquoter configuration
# --------------------------------------------------------
export ZAQ_PREFIXES=(
  'git ci( [^ ]##)# -[^ -]#m'
  'git commit( [^ ]##)# -[^ -]#m'
  'git stash save( [^ ]##)#'
  'ddgr( [^ ]##)#'
  'gh copilot explain( [^ ]##)#'
  'gh copilot suggest( [^ ]##)#'
  'claude -p( [^ ]##)#'
)

# --------------------------------------------------------
# zsh-autosuggestions config
# --------------------------------------------------------

# must choose a value greater than 8, see https://github.com/zsh-users/zsh-autosuggestions/issues/698
# for the complete list of 256 colors: https://upload.wikimedia.org/wikipedia/commons/1/15/Xterm_256color_chart.svg
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=244"
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=10

# zsh-syntax-highlighting config
export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern zaq)

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
