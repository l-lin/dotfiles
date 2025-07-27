#!/usr/bin/env zsh
#
# Optimizations for reducing first command lag
#

# Enable path hashing for faster command lookup
setopt HASH_CMDS
setopt HASH_DIRS

# Disable command correction (can cause lag)
unsetopt CORRECT
unsetopt CORRECT_ALL

# Optimize command lookup
setopt NO_PATH_DIRS

# Skip rehashing on every command (manual rehash when needed)
setopt NO_HASH_LIST_ALL

# Cache command locations
zstyle ':completion:*' accept-exact-dirs true
zstyle ':completion:*' rehash false

# Optimize history search
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

