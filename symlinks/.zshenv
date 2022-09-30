skip_global_compinit=1

# --------------------------------------------------------
# User configuration
# --------------------------------------------------------

export APPS_HOME="$HOME/apps"
export PATH="$HOME/bin:$PATH"

export GREP_COLOR=32

# hack to fix mouse hover in Firefox on Ubuntu 22
# https://www.reddit.com/r/firefox/comments/wm2kr5/mouse_hover_not_consistent_firefox_103_ubuntu/
export MOZ_ENABLE_WAYLAND=1
