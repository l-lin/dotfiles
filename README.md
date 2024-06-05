# Dotfiles

This [dotfiles](http://dotfiles.github.io) is made to be worked with [ArchCraft](https://archcraft.io/).
It's using the following:

- [openbox](http://openbox.org/wiki/Main_Page): next generation window manager
- [alacritty](https://github.com/alacritty/alacritty): A cross-platform, OpenGL terminal emulator.
- [rofi](https://github.com/davatorium/rofi): window switcher, application launcher and dmenu replacement
- [thunar](https://docs.xfce.org/xfce/thunar/start): file manager
- [polybar](https://polybar.github.io/): fast and easy to use tool for creating status bars
- [dunst](https://dunst-project.org/): lightweight replacement for the notification daemons
- [plank](https://launchpad.net/plank): application dock

Credit to [AlbertoV](https://www.deviantart.com/albertov) for his awesome [Totoro pixel art](./openbox/.config/openbox/themes/gruvbox/wallpaper).

## Install & bootstraping dotfiles

```bash
make help
```

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

```bash
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

### Install Openfortivpn
#### From sources

```bash
# first install pre-requisites: https://github.com/gm-vm/openfortivpn#building-and-installing-from-source
yay -S --noconfirm gcc automake autoconf make pkg-config

# clone project
git clone https://github.com/gm-vm/openfortivpn.git
cd openfortivpn

# build project
./autogen.sh
./configure --prefix=/usr/local --sysconfdir=/etc
make
sudo make install

# check openfortivpn is installed correctly
openfortivpn --version
```

#### From AUR

```bash
yay -S openfortivpn
```

### Install Openfortivpn webview

```bash
# download openfortivpn-webview to get the cookie
wget -qO- https://github.com/gm-vm/openfortivpn-webview/releases/download/v1.1.0-electron/openfortivpn-webview-1.1.0.tar.xz \
  | sudo tar -xvJ --transform='s/openfortivpn-webview-1.1.0/openfortivpn-webview/g' -C /usr/local \
  && sudo ln -s /usr/local/openfortivpn-webview/openfortivpn-webview /usr/local/bin/openfortivpn-webview
```

### Usage

```bash
# open VPN in one command line
VPN_HOST=some_host && VPN_PORT=443 \
  && openfortivpn-webview "${VPN_HOST}:${VPN_PORT}" 2>/dev/null \
  | sudo openfortivpn "${VPN_HOST}:${VPN_PORT}" --cookie-on-stdin --pppd-accept-remote
```

Note: we need to add the `--pppd-accept-remote` since `ppp` v2.5.0.
See https://github.com/adrienverge/openfortivpn/issues/1076 for more information.

---
# :snowflake: NisOS dotfiles

## Getting started

```bash
make help
```

### Fresh NixOS installation

For bootstrapping a fresh NixOS install as root:

```bash
nix-shell -p git gnumake
git clone https://github.com/l-lin/dotfiles
cd dotfiles
make nixos
reboot now
```

## Resources

There are lots of Nix documentation, but it's quite hard to find the "right" one depending on your level of understanding of Nix.
The official Nix documentation delves a bit too much on the concepts (for the right reasons), whereas I just want to make something work fast.

I found [Evertras introduction to home-manager](https://github.com/Evertras/simple-homemanager) is the best documentation to start with Nix, along with https://zero-to-nix.com/.

### Search packages

- https://search.nixos.org or using command line:

```bash
nix search nixpkgs your_package
```

- https://mynixos.com

### References

- https://nix.dev/manual/nix/2.22/command-ref/new-cli/nix

### Tutorials

- https://github.com/Evertras/simple-homemanager: best introduction to home-manager for newcomer
- https://zero-to-nix.com/
- https://nix.dev
- https://josiahalenbrown.substack.com/p/installing-nixos-with-hyprland
- https://www.bekk.christmas/post/2021/16/dotfiles-with-nix-and-home-manager
- https://gist.github.com/thiloho/993be8693571c9868c1661ae0f3c776b
- [writing Nix modules](https://nixos.org/manual/nixos/stable/#sec-writing-modules)
- [Nix module system](https://nix.dev/tutorials/module-system/)

### Example of nix config

- https://github.com/GaetanLepage/nix-config
- https://github.com/ryan4yin/nix-config
- https://gitlab.com/Zaney/zaneyos
- https://github.com/Misterio77/nix-starter-configs
- https://github.com/Evertras/nix-systems

