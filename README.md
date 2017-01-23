# Dotfiles

See [dotfiles](http://dotfiles.github.io).

![dotfiles](dotfiles.gif)

# List of applications to install after reinstalling Xubuntu

```
sudo add-apt-repository ppa:git-core/ppa
sudo apt-get update
# Install additional commands
sudo apt-get install build-essential cmake git zsh fortune cowsay colorDiff vim exuberant-ctags tmux
# Install pip
sudo apt-get install python-pip python-dev build-essential 
sudo pip install --upgrade pip 
sudo pip install --upgrade virtualenv 
# Install power-line for VIM airline
sudo pip install powerline-status
# Instal TMUX plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# Install stuffs
sudo apt-get install byzanz fortune cowsay colordiff
# Install NodeJS on root
# Install https://github.com/tj/n
sudo npm install -g n
# Install https://github.com/mixu/gr
sudo npm install -g git-run
# Bootstrap dotfiles
./bootstrap.sh
```

