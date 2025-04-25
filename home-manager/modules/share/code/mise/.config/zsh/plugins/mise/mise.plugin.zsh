#!/usr/bin/env zsh
#
# Content of the command: eval "$(mise activate zsh)"
# `eval` is quite slow. Instead, we can just copy the content to improve the prompt performance.
# src: https://www.dribin.org/dave/blog/archives/2024/01/01/zsh-performance/
#

if ! type mise >/dev/null 2>&1; then
  return
fi

export MISE_SHELL=zsh
export __MISE_ORIG_PATH="$PATH"

mise() {
  local command
  command="${1:-}"
  if [ "$#" = 0 ]; then
    command /Users/louis.lin/.nix-profile/bin/mise
    return
  fi
  shift

  case "$command" in
  deactivate|shell|sh)
    # if argv doesn't contains -h,--help
    if [[ ! " $@ " =~ " --help " ]] && [[ ! " $@ " =~ " -h " ]]; then
      eval "$(command /Users/louis.lin/.nix-profile/bin/mise "$command" "$@")"
      return $?
    fi
    ;;
  esac
  command /Users/louis.lin/.nix-profile/bin/mise "$command" "$@"
}

_mise_hook() {
  eval "$(/Users/louis.lin/.nix-profile/bin/mise hook-env -s zsh)";
}
typeset -ag precmd_functions;
if [[ -z "${precmd_functions[(r)_mise_hook]+1}" ]]; then
  precmd_functions=( _mise_hook ${precmd_functions[@]} )
fi
typeset -ag chpwd_functions;
if [[ -z "${chpwd_functions[(r)_mise_hook]+1}" ]]; then
  chpwd_functions=( _mise_hook ${chpwd_functions[@]} )
fi

_mise_hook
if [ -z "${_mise_cmd_not_found:-}" ]; then
    _mise_cmd_not_found=1
    [ -n "$(declare -f command_not_found_handler)" ] && eval "${$(declare -f command_not_found_handler)/command_not_found_handler/_command_not_found_handler}"

    function command_not_found_handler() {
        if [[ "$1" != "mise" && "$1" != "mise-"* ]] && /Users/louis.lin/.nix-profile/bin/mise hook-not-found -s zsh -- "$1"; then
          _mise_hook
          "$@"
        elif [ -n "$(declare -f _command_not_found_handler)" ]; then
            _command_not_found_handler "$@"
        else
            echo "zsh: command not found: $1" >&2
            return 127
        fi
    }
fi
