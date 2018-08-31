#!/bin/bash

set -e
set -x

echo "[-] Installing Git Run: https://github.com/mixu/gr"
npm i -g git-run
echo "[-] Installing Yarn"
npm i -g yarn
echo "[-] Installing tldr: http://tldr-pages.github.io/"
npm i -g tldr

exit 0
