#!/usr/bin/env zsh
#
# Content of the command: eval "$(mise activate zsh)"
# `eval` is quite slow. Instead, we can just copy the content to improve the prompt performance.
# src: https://www.dribin.org/dave/blog/archives/2024/01/01/zsh-performance/
#

if [ -n "$REX_BIN_DIR" ]; then
    export PATH="$REX_BIN_DIR:$PATH"
fi
