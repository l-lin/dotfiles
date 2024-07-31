#!/usr/bin/env sh
#
# Script based and adapted from: https://github.com/denisidoro/navi/blob/master/docs/tmux.md.
# The example provided uses split-window whereas I want to use Tmux popup.
#

tmux bind-key "C-f" \
  popup -w "90%" -h "90%" -E \
  "navi --print | head -c -1 | tmux load-buffer -b tmp - ; tmux paste-buffer -p -b tmp -d"
