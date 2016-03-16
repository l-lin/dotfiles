#!/bin/bash

function help() {
    echo "[x] Missing arguments..."
    echo "[-] Usage:"
    echo "[-]    $ $0 <url> <selector>"
    echo "[-]    $ $0 http://www.translationnations.com/translations/stellar-transformations/st-book-16-chapter-21/"
    echo "[-]    $ $0 http://www.arantranslations.com/137-just-who-do-you-think-you-are/ .post-content"
    exit 1
}

if [ $# -eq 0 ] 
then
    help
fi

if [ -z "$1" ]
then
    help
fi

URL=${1}
SELECTOR=${2:-.entry-content}

wring text ${URL} ${SELECTOR}

exit 0
