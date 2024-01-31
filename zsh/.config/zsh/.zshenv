#
# .zshenv - Zsh environment file, loaded always.
#

export ZDOTDIR=$HOME/.config/zsh

# zsh custom folder
export ZSH_CUSTOM=${ZDOTDIR}

# import zprofiles
for f in "${ZDOTDIR}"/zprofile.d/.zprofile*; do
  source "$f"
done

# vim: ft=zsh
