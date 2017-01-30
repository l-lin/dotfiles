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
sudo apt-get install byzanz colordiff htop
# Install NodeJS on root
# Install https://github.com/tj/n
sudo npm install -g n
# Install https://github.com/mixu/gr
sudo npm install -g git-run
# Install zsh plugins
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/paulirish/git-open.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/git-open
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# Bootstrap dotfiles
./bootstrap.sh
# https://github.com/psprint/zsh-navigation-tools#fixing-tmux-screen-and-linux-vt 
{ infocmp -x screen-256color; printf '\t%s\n' 'ncv@,'; } > /tmp/t && tic -x /tmp/t
```

