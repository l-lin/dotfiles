#
# .zprofile - for login shells
#

# import zprofiles
for f in "${ZDOTDIR}"/zprofile.d/.zprofile*; do
  source "${f}"
done

