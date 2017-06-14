# Dotfiles

See [dotfiles](http://dotfiles.github.io).

![dotfiles](dotfiles.gif)

# List of applications to install after reinstalling Xubuntu

```
sudo add-apt-repository ppa:git-core/ppa
sudo apt-get update
# Install additional commands
sudo apt-get install build-essential cmake git zsh fortune cowsay colorDiff vim exuberant-ctags tmux python-pip python-dev
# Install nodeJS: https://nodejs.org/en/
# Install NVM: https://github.com/creationix/nvm
# Launch stuff installation
./install.sh
# Bootstrap dotfiles
./bootstrap.sh
```

# Install VIM plugins

- Edit a file with VIM
- Execute `:PlugInstall`

# Install TMUX plugins

- Press "Prefix + I" (capital i)

