#!/usr/bin/env zsh
# Some tools, like extrakto, have some issue with the env variable
# FZF_DEFAULT_OPTS, and the easiest way to work around it is to
# force source the current shell.
#
# See https://github.com/laktak/extrakto/issues/78

source ~/.zshenv
/usr/bin/fzf $@

