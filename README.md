# Dotfiles

See [dotfiles](http://dotfiles.github.io).

![dotfiles](dotfiles.gif)

# List of applications to install after reinstalling the OS

```bash
# create symlinks & install stuffs
./install.sh

# only creating symlinks
./bootstrap.sh
```

# Install VIM plugins

- Edit a file with VIM
- Execute `:PlugInstall`
- Install Coc extensions:
  - `:CocInstall coc-json`
  - `:CocInstall coc-go`
  - `:CocInstall coc-tsserver`
  - `:CocInstall coc-rls`

# Install TMUX plugins

- Press "Prefix + I" (capital i)

# Install Ubuntu gnome extensions

- Install browser extension `GNOME shell`
- Install the following:
  - [Clipboard indicator](https://extensions.gnome.org/extension/779/clipboard-indicator/)
  - [Dash to panel](https://extensions.gnome.org/extension/1160/dash-to-panel/)
  - [Do not disturb](https://extensions.gnome.org/extension/964/do-not-disturb-button/)
  - [Sensory perception](https://extensions.gnome.org/extension/1145/sensory-perception/)
  - [System monitor](https://extensions.gnome.org/extension/120/system-monitor/)
  - [User themes](https://extensions.gnome.org/extension/19/user-themes/)

# Terminal configuration

- Font: OverpassMono Nerd Font Regular

# Calibre

## Installation

```bash
sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin
```

## Configuration

- Go to "Fetch news > Add or edit a custom resource"
- Click on "New recipe"
  - Set "Oldest article": 2 days
  - Feed URL: http://getpocket.com/users/<username>/feed/unread
- Click on "Preferences > Sharing books by email"
  - Add email
  - Setup the email server
    - Hostname: smtp.gmail.com
    - Port: 587
    - Encryption: TLS

# IntellIJ plugins

- AceJump
- AsciiDoc
- CodeGlance
- Emoji support plugin
- Error prone compiler
- Grep console
- Handlebars/Mustache
- IdeaVim
- IdeaVim-EasyMotion
- Ideolog
- IntelliJDeodorant
- Lombok
- MyGruvbox Theme
- Property sorter
- Scala
- SonarLint
- Spring assistant

