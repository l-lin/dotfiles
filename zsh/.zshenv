skip_global_compinit=1

# --------------------------------------------------------
# FZF options
# --------------------------------------------------------
#
# Nord theme:
#export FZF_DEFAULT_OPTS="
#--ansi
#--color fg:#D8DEE9,bg:-1,hl:#A3BE8C,fg+:#D8DEE9,bg+:#434C5E,hl+:#A3BE8C
#--color pointer:#BF616A,info:#4C566A,spinner:#4C566A,header:#4C566A,prompt:#81A1C1,marker:#EBCB8B
#--bind='?:toggle-preview'
#--bind='alt-p:toggle-preview-wrap'
#--preview-window='right:60%:wrap'
#"
# Gruvbox theme: https://github.com/luisiacc/gruvbox-baby/blob/main/extras/tmux/MEDIUM.tmux
export FZF_THEME="
--color=fg:#EBDBB2 \
--color=bg:#282828 \
--color=hl:#FABD2F \
--color=fg+:bold:#EBDBB2 \
--color=bg+:#665C54 \
--color=hl+:#FABD2F \
--color=gutter:#282828 \
--color=info:#D65D0E \
--color=separator:#282828 \
--color=border:#E7D7AD \
--color=label:#EEBD35 \
--color=prompt:#7FA2AC \
--color=spinner:#FABD2F \
--color=pointer:bold:#FABD2F \
--color=marker:#CC241D \
--color=header:#D65D0E \
--color=preview-fg:#EBDBB2 \
--color=preview-bg:#282828 \
"
export FZF_DEFAULT_OPTS="
--bind='?:toggle-preview'
--bind='alt-p:toggle-preview-wrap'
--preview-window='right:60%:wrap'
${FZF_THEME}
"
export FZF_TMUX_OPTS="-p 80%,80%"
# preview content of the file under the cursor when searching for a file
export FZF_CTRL_T_OPTS="--preview 'bat --style numbers,changes --color "always" {} | head -200'"
# preview full command
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:5:wrap"
# show the entries of the directory
export FZF_ALT_C_OPTS="--sort --preview 'tree -C {} | head -200'"

# --------------------------------------------------------
# zsh-autosuggestions config
# --------------------------------------------------------

# must choose a value greater than 8, see https://github.com/zsh-users/zsh-autosuggestions/issues/698
# for the complete list of 256 colors: https://upload.wikimedia.org/wikipedia/commons/1/15/Xterm_256color_chart.svg
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=244"
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=10

# zsh-syntax-highlighting config
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern zaq)

# --------------------------------------------------------
# zsh-autoquoter configuration
# --------------------------------------------------------

ZAQ_PREFIXES=(
  'g ci( [^ ]##)# -[^ -]#m'
  'g commit( [^ ]##)# -[^ -]#m'
  'g stash save( [^ ]##)#'
)

# --------------------------------------------------------
# User configuration
# --------------------------------------------------------

export APPS_HOME="$HOME/apps"
export PATH="$HOME/bin:$PATH"

export GREP_COLORS='mt=32'

# hack to fix mouse hover in Firefox on Ubuntu 22
# https://www.reddit.com/r/firefox/comments/wm2kr5/mouse_hover_not_consistent_firefox_103_ubuntu/
export MOZ_ENABLE_WAYLAND=1

export MAVEN_OPTS="-Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=WARN -Dorg.slf4j.simpleLogger.showDateTime=true -Dorg.slf4j.simpleLogger.dateTimeFormat=HH:mm:ss"
