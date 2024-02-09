#
# .zprofile - for login shells
#

# import colorscheme
[[ -f "${ZDOTDIR}/.zsh_colorscheme" ]] && . "${ZDOTDIR}/.zsh_colorscheme"

# import zprofiles
for f in "${ZDOTDIR}"/zprofile.d/.zprofile*; do
  . "${f}"
done

