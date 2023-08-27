skip_global_compinit=1

# --------------------------------------------------------
# FZF options
# --------------------------------------------------------
export FZF_COLORSCHEME='github-light'
if [ "${FZF_COLORSCHEME}" = 'gruvbox-light' ]; then
  ZSH_THEME_BG='#fbf1c7'
  ZSH_THEME_FG='#3c3836'
  ZSH_THEME_BLACK='#fbf1c7'
  ZSH_THEME_RED='#cc241d'
  ZSH_THEME_GREEN='#98971a'
  ZSH_THEME_YELLOW='#d79921'
  ZSH_THEME_BLUE='#458588'
  ZSH_THEME_MAGENTA='#b16286'
  ZSH_THEME_CYAN='#689d6a'
  ZSH_THEME_WHITE='#7c6f64'
  ZSH_THEME_GRAY='#928374'
  ZSH_THEME_ACCENT="${ZSH_THEME_YELLOW}"
elif [ "${FZF_COLORSCHEME}" = "gruvbox-dark" ]; then
  ZSH_THEME_BG='#282828'
  ZSH_THEME_FG='#ebdbb2'
  ZSH_THEME_BLACK='#282828'
  ZSH_THEME_RED='#cc241d'
  ZSH_THEME_GREEN='#98971a'
  ZSH_THEME_YELLOW='#d79921'
  ZSH_THEME_BLUE='#458588'
  ZSH_THEME_MAGENTA='#b16286'
  ZSH_THEME_CYAN='#689d6a'
  ZSH_THEME_WHITE='#a89984'
  ZSH_THEME_GRAY='#928374'
  ZSH_THEME_ACCENT="${ZSH_THEME_YELLOW}"
elif [ "${FZF_COLORSCHEME}" = "kanagawa" ]; then
  ZSH_THEME_BG='#1f1f28'
  ZSH_THEME_FG='#dcd7ba'
  ZSH_THEME_BLACK='#090618'
  ZSH_THEME_RED='#c34043'
  ZSH_THEME_GREEN='#76946a'
  ZSH_THEME_YELLOW='#c0a36e'
  ZSH_THEME_BLUE='#7e9cd8'
  ZSH_THEME_MAGENTA='#957fb8'
  ZSH_THEME_CYAN='#6a9589'
  ZSH_THEME_WHITE='#c8c093'
  ZSH_THEME_GRAY='#727169'
  ZSH_THEME_ACCENT="${ZSH_THEME_BLUE}"
elif [ "${FZF_COLORSCHEME}" = "github-light" ]; then
  ZSH_THEME_BG='#ffffff'
  ZSH_THEME_FG='#010409'
  ZSH_THEME_BLACK='#0e1116'
  ZSH_THEME_RED='#a0111f'
  ZSH_THEME_GREEN='#024c1a'
  ZSH_THEME_YELLOW='#3f2200'
  ZSH_THEME_BLUE='#0349b4'
  ZSH_THEME_MAGENTA='#622cbc'
  ZSH_THEME_CYAN='#1b7c83'
  ZSH_THEME_WHITE='#66707b'
  ZSH_THEME_GRAY='#4b535d'
  ZSH_THEME_ACCENT="${ZSH_THEME_BLUE}"
fi
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
  'ddg( [^ ]##)#'
)

# --------------------------------------------------------
# zsh vi mode
# --------------------------------------------------------
export ZVM_VI_EDITOR=nvim
export ZVM_KEYTIMEOUT=0.1

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
export JDTLS_JVM_ARGS="-javaagent:$HOME/.local/share/nvim/mason/packages/jdtls/lombok.jar"

