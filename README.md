# Dotfiles

This [dotfiles](http://dotfiles.github.io) is made to be worked with [ArchCraft](https://archcraft.io/).
It's using the following:

- [openbox](http://openbox.org/wiki/Main_Page): next generation window manager
- [xfce4-terminal](https://docs.xfce.org/apps/xfce4-terminal/start): terminal emulator
- [rofi](https://github.com/davatorium/rofi): window switcher, application launcher and dmenu replacement
- [thunar](https://docs.xfce.org/xfce/thunar/start): file manager
- [polybar](https://polybar.github.io/): fast and easy to use tool for creating status bars
- [dunst](https://dunst-project.org/): lightweight replacement for the notification daemons
- [plank](https://launchpad.net/plank): application dock

Credit to [AlbertoV](https://www.deviantart.com/albertov) for his awesome [Totoro pixel art](./openbox-themes/.config/openbox-themes/themes/gruvbox/wallpaper).

## Install & bootstraping dotfiles

```bash
make help
```

## Install VIM plugins

- Edit a file with VIM
- Execute `:PackerSync` (should be executed automatically)

## Install TMUX plugins

- Press "Prefix + I" (capital i)

## Calibre
### Installation

```bash
sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin
```

### Configuration

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

## IntellIJ plugins

- AceJump
- Ansible
- CodeGlance
- Grep console
- Maven Helper
- MyGruvbox theme
- IdeaVim
- Ideolog
- Settings repository
- SonarLint
- Terraform and HCL

## Pair keyboard with bluetooth

```bash
$ # install bluez and bluez-utils if not already done
$ yay -S bluez bluez-utils

$ # start bluetooth service
$ sudo systemctl start bluetooth
$ # enable bluetooth service on startup
$ sudo systemctl enable bluetooth

$ # execute bluetoothctl
$ bluetoothctl
Agent registered
[CHG] Controller XX:XX:XX:XX:XX:XX Pairable: yes
[bluetooth]#
[bluetooth]# power on
[bluetooth]# agent on
[bluetooth]# default-agent
[bluetooth]# scan on
<...>
[NEW] Device YY:YY:YY:YY:YY:YY [ERGO K860]
<...>
[bluetooth]# connect YY:YY:YY:YY:YY:YY
[bluetooth]# trust YY:YY:YY:YY:YY:YY
[bluetooth]# quit
```

ℹ️ : some keyboards sends a pass code which has to be typed in on the
bluetooth keyboard followed by the key "Enter" in order to pair
successfully.

```
[bluetooth]# pair YY:YY:YY:YY:YY:YY
[CHG] Device YY:YY:YY:YY:YY:YY Connected: no
[CHG] Device YY:YY:YY:YY:YY:YY Connected: yes
[agent] Passkey: 103760
```

Sources:

- https://bbs.archlinux.org/viewtopic.php?id=258125
- https://wiki.archlinux.org/title/Bluetooth_keyboard
- https://medium.com/@n0tty/bluetooth-and-arch-linux-a1ae56599256

## Forticlient VPN with SAML

If the official client does not work with your OS, there is a workaround available: https://gitlab.com/openconnect/openconnect/-/issues/356

```bash
# first install pre-requisites: https://github.com/gm-vm/openfortivpn#building-and-installing-from-source
yay -S --noconfirm gcc automake autoconf make pkg-config

# clone project
git clone https://github.com/gm-vm/openfortivpn.git
cd openfortivpn
git checkout svpn_cookie

# build project
./autogen.sh
./configure --prefix=/usr/local --sysconfdir=/etc
make
sudo make install

# check openfortivpn is installed correctly
openfortivpn --version

# download openfortivpn-webview to get the cookie
curl -L -o openfortivpn-webview.tar.xz https://github.com/gm-vm/openfortivpn-webview/releases/download/v1.0.1-electron/openfortivpn-webview-1.0.1.tar.xz
extract openfortivpn-webview

# create symlink in a bin folder so we can execute from everywhere
sudo ln -s openfortivpn-webview/openfortivpn-webview /usr/local/bin/openfortivpn-webview

# open VPN in one command line
HOST=some_host && PORT=443 && \
  openfortivpn-webview $HOST:$PORT 2>/dev/null \
  | sudo openfortivpn $HOST:$PORT --svpn-cookie -
```

