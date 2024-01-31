#
# sensible default set by zephyr
# src: https://github.com/mattmc3/zephyr/blob/main/plugins/environment/environment.plugin.zsh
#

# --------------------------------------------------------
# FZF options
# --------------------------------------------------------
export ZSH_THEME_BG='#1f1f28'
export ZSH_THEME_FG='#dcd7ba'
export ZSH_THEME_BLACK='#090618'
export ZSH_THEME_RED='#c34043'
export ZSH_THEME_GREEN='#76946a'
export ZSH_THEME_YELLOW='#c0a36e'
export ZSH_THEME_BLUE='#7e9cd8'
export ZSH_THEME_MAGENTA='#957fb8'
export ZSH_THEME_CYAN='#6a9589'
export ZSH_THEME_WHITE='#c8c093'
export ZSH_THEME_GRAY='#727169'
export ZSH_THEME_ACCENT='#7e9cd8'

export FZF_THEME="
--color=bg:${ZSH_THEME_BG}
--color=hl:${ZSH_THEME_ACCENT}
--color=fg:${ZSH_THEME_FG}
--color=fg+:bold:${ZSH_THEME_FG}
--color=bg+:${ZSH_THEME_BG}
--color=hl+:${ZSH_THEME_ACCENT}
--color=gutter:${ZSH_THEME_BG}
--color=info:${ZSH_THEME_GRAY}
--color=separator:${ZSH_THEME_ACCENT}
--color=border:${ZSH_THEME_GRAY}
--color=label:${ZSH_THEME_RED}
--color=prompt:${ZSH_THEME_RED}
--color=spinner:${ZSH_THEME_GRAY}
--color=pointer:bold:${ZSH_THEME_RED}
--color=marker:${ZSH_THEME_RED}
--color=header:${ZSH_THEME_RED}
--color=preview-fg:${ZSH_THEME_FG}
--color=preview-bg:${ZSH_THEME_BG}
--no-scrollbar
--prompt='󰍉 '
"
export FZF_DEFAULT_OPTS="
--bind='?:toggle-preview' \
--bind='alt-p:toggle-preview-wrap' \
--preview-window='right:40%:border-none' \
--tiebreak=chunk \
--cycle \
${FZF_THEME}
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
