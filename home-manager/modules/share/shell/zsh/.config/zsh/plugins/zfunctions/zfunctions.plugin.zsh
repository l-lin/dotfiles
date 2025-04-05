#!/usr/bin/env zsh
#
# zfunctions: use a Fish-like functions directory for zsh functions.
# src: https://github.com/mattmc3/zephyr/blob/main/plugins/zfunctions/zfunctions.plugin.zsh
# adapted to support symlinks
#

# Load zfunctions.
if [[ -z "$ZFUNCDIR" ]]; then
  ZFUNCDIR=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config/zsh}}/functions
fi

fpath=("$ZFUNCDIR" $fpath)
autoload -Uz $fpath[1]/*

# Load zfunctions subdirs.
for _fndir in $ZFUNCDIR(N/) $ZFUNCDIR/*(N/); do
  fpath=("$_fndir" $fpath)
  autoload -Uz $fpath[1]/*
done
unset _fndir

