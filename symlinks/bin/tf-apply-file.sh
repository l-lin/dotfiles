#!/usr/bin/env bash

set -eu

target_env='sandbox'

show_help() {
  cat << EOF
Perform `terraform apply` for given files. This script is useful
if you do not want to apply the whole directory.

Usage: ${0##*/} <flags> <files separated by spaces>

Examples:
    # apply in sandbox env
      ${0##*/} --env sanbox file1.tf file2.tf
    # Use bar
      ${0##*/} bar azerty

Flags:
    -h, --help            Display help
    -e, --env             Target environment (default: ${target_env})

EOF
}


main() {
  local name=
  local verbose=false
  # Flags in bash tutorial here: /usr/share/doc/util-linux/examples/getopt-example.bash
  TEMP=$(getopt -o 'he:' --long 'help,env:' -n "${0##*/}" -- "$@")
  eval set -- "$TEMP"
  unset TEMP
  while true; do
    case "${1}" in
      '-h'|'--help')
        show_help
        exit
        ;;
      '-e'|'--env')
        target_env="${2}"
        shift 2
        continue
        ;;
      '--')
        shift
        break
        ;;
      *)
        break
        ;;
    esac

    shift
  done

  apply_tf "$@"
}

apply_tf() {
  local files=${@}
  local target_flags=""

  for f in ${files[@]}; do
    targets=($(cat ${f} | grep 'resource "' | sed 's/"//g' | awk '{ print "--target" " " $2 "." $3 }' | tr '\n' ' '))
    for target in ${targets[@]}; do
      target_flags+="${target} "
    done
  done

  terraform apply -var-file=../../config/${target_env}/${target_env}.tfvars ${target_flags}
}

main "$@"
