#!/bin/bash

set -e
set -x

echo "[-] Installing Git Run: https://github.com/mixu/gr"
npm i -g git-run
echo "[-] Installing Yarn"
npm i -g yarn
echo "[-] Installing tldr: http://tldr-pages.github.io/"
npm i -g tldr
echo "[-] Installing git-recall: https://github.com/Fakerr/git-recall"
npm i -g git-recall
echo "[-] Installing tiny-care-terminal: https://github.com/notwaldorf/tiny-care-terminal"
npm i -g tiny-care-terminal

exit 0
