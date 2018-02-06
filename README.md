# Dotfiles

See [dotfiles](http://dotfiles.github.io).

![dotfiles](dotfiles.gif)

# List of applications to install after reinstalling Xubuntu

```bash
sudo add-apt-repository ppa:git-core/ppa
sudo apt-get update
# Install additional commands
sudo apt-get install build-essential cmake git zsh fortune cowsay colordiff vim exuberant-ctags tmux python-pip python-dev ruby-dev ruby htop xclip httpie
# Install nodeJS https://nodejs.org/en/ in $HOME/apps/nodejs folder
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

