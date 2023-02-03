skip_global_compinit=1

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
