#
# sensible default set by zephyr
# src: https://github.com/mattmc3/zephyr/blob/main/plugins/environment/environment.plugin.zsh
#

# --------------------------------------------------------
# FZF options
# --------------------------------------------------------
export FZF_DEFAULT_OPTS="
--bind='?:toggle-preview' \
--bind='alt-p:toggle-preview-wrap' \
--preview-window='right:40%:border-none' \
--tiebreak=chunk \
--cycle \
--no-scrollbar
--prompt='󰍉 '
"
export FZF_TMUX_OPTS="-p 90%,90%"
# preview content of the file under the cursor when searching for a file
export FZF_CTRL_T_OPTS="--no-reverse --preview 'bat --style changes --color "always" {} | head -200'"
# preview full command
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:5:wrap"
# show the entries of the directory
export FZF_ALT_C_OPTS="--no-reverse --sort --preview 'tree -C {} | head -200'"
# display hidden files with CTRL-T command
export FZF_CTRL_T_COMMAND="fd --type f --hidden --exclude .git"
# display hidden folders with ATL-C command
export FZF_ALT_C_COMMAND="fd --type d --hidden --exclude .git"

# --------------------------------------------------------
# navi config
# --------------------------------------------------------
export NAVI_FZF_OVERRIDES_VAR="--preview-window top:50%:wrap:border"

# --------------------------------------------------------
# zsh-autoquoter configuration
# --------------------------------------------------------
export ZAQ_PREFIXES=(
  'git ci( [^ ]##)# -[^ -]#m'
  'git commit( [^ ]##)# -[^ -]#m'
  'git stash save( [^ ]##)#'
  'ddgr( [^ ]##)#'
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

export MAVEN_OPTS="-Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=WARN -Dorg.slf4j.simpleLogger.showDateTime=true -Dorg.slf4j.simpleLogger.dateTimeFormat=HH:mm:ss"
export JDTLS_JVM_ARGS="-javaagent:$HOME/.local/share/nvim/mason/packages/jdtls/lombok.jar"

# find & replace + rename diff tool to use
export REP_PAGER="delta"
export REN_PAGER="delta"

export EDITOR="nvim"

# vim: ft=zsh
