#!/usr/bin/env bash
#
# This hook will look for code comments marked 'NOCOMMIT' to prevent
# committing unwanted lines.
# src: https://stackoverflow.com/a/20574486
#

set -e

keyword="NOCOMMIT"

no_commit_count=$(git diff --no-ext-diff --cached | rg "${keyword}" | wc -l)
if [ "${no_commit_count}" -ne "0" ]; then
   echo "WARNING: You are attempting to commit changes which include a '${keyword}'. Please check the following files:"
   echo
   git diff --no-ext-diff --cached --name-only -i -G"${keyword}" | sed 's/^/   - /'
   echo
   echo "You can ignore this warning by running the commit command with '--no-verify'"
   exit 1
fi
