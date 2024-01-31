#!/usr/bin/env zsh
#
# asdf support
#

# add asdf bin / shims to $PATH
path=(${ASDF_DIR}/{bin,shims}(N) $path)

