#!/usr/bin/env zsh
#
# Antidote is a Zsh plugin manager made from the ground up thinking about performance.
# It is fast because it can do things concurrently, and generates an ultra-fast static plugin file that you can easily load from your Zsh config.
# src: https://getantidote.github.io/
#

# zsh custom folder
export ZSH_CUSTOM=${ZDOTDIR:-$HOME/.config/zsh}

# plugin management
export ANTIDOTE_HOME="${XDG_CACHE_HOME:=$HOME/.cache}/antidote"
export ANTIDOTE_BUNDLE_FILE="${ANTIDOTE_HOME}/plugins.antidote"
export ANTIDOTE_STATIC_FILE="${ANTIDOTE_HOME}/plugins.zsh"

# Clone antidote if missing.
[[ -d "${ANTIDOTE_HOME}/mattmc3/antidote" ]] || git clone --depth 1 --quiet https://github.com/mattmc3/antidote "${ANTIDOTE_HOME}/mattmc3/antidote"
source ${ANTIDOTE_HOME}/mattmc3/antidote/antidote.zsh

# Generate the antidote plugin static file if it does not exist yet.
# Antidote static file is the cache file used to load all the plugins.
# Can be regenerated by calling `refresh-zsh-antidote-plugins`
if [[ ! -r ${ANTIDOTE_STATIC_FILE} ]]; then
  # Ensure `plugins.antidote` is always first!
  cat ${ZDOTDIR}/plugins/plugins.antidote > ${ANTIDOTE_BUNDLE_FILE}
  for zplugin in ${ZDOTDIR}/plugins/**/*.antidote; do
    if [[ ${zplugin##*/} != ${ANTIDOTE_BUNDLE_FILE##*/} ]]; then
      cat ${zplugin} >> ${ANTIDOTE_BUNDLE_FILE}
    fi
  done
  unset zplugin
  antidote bundle < ${ANTIDOTE_BUNDLE_FILE} > ${ANTIDOTE_STATIC_FILE}
fi

source ${ANTIDOTE_STATIC_FILE}
