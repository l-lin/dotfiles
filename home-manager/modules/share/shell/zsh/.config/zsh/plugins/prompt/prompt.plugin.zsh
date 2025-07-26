#!/usr/bin/env zsh
#
# Set prompt.
#
# src:
# - https://github.com/mattmc3/zdotdir/blob/fd781dc4005110b0ae82f596e205fd020f5657a8/.zshrc#L61-L66
# - https://github.com/mattmc3/zephyr/issues/13
#

# Set prompt theme
setopt prompt_subst transient_rprompt

[[ ! -f "${ZDOTDIR}/themes/lean.p10k.zsh" ]] || source "${ZDOTDIR}/themes/lean.p10k.zsh"

# Define p10k function to add a custom prompt segment.
function prompt_remote_context() {
  if [[ ! -z "${PROMPT_REMOTE_CONTEXT}" ]]; then
    p10k segment -b 1 -f 3 -i '⚠️' -t "${PROMPT_REMOTE_CONTEXT}"
  fi
}
