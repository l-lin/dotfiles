# pet: https://github.com/knqyf263/pet
if type pet >/dev/null 2>&1; then
    function pet-select() {
        BUFFER=$(pet search --query "$LBUFFER")
        CURSOR=$#BUFFER
        zle redisplay
    }
    zle -N pet-select
    stty -ixon
    bindkey '^s' pet-select

    function pet-register-prev() {
      PREV=$(fc -lrn | head -n 1)
      sh -c "pet new `printf %q "$PREV"`"
    }
fi
