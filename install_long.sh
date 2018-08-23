#!/bin/bash

set -e
set -x

echo "[-] Installing colorls: https://github.com/athityakumar/colorls"
git clone https://github.com/ryanoasis/nerd-fonts --depth 1 /tmp/nerd-fonts
cd /tmp/nerd-fonts && ./install.sh

echo "[-] Finished SUCCESSFULLY"
exit 0
