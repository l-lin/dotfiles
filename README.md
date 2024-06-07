# :snowflake: NixOS dotfiles

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
make home
reboot
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

- https://github.com/Misterio77/nix-starter-configs
  - os: nixos
  - note: starter point for all new nixos configuration project
- https://github.com/GaetanLepage/nix-config
  - os: nixos
  - wm: sway
  - terminal emulator: foot
  - launcher: rofi
  - pdf viewer: zathura
  - browser: firefox
  - note:
    - minimalist README
- https://github.com/ryan4yin/nix-config
  - os: nixos
  - wm: hyprland, i3
  - terminal emulator: kitty, wezterm
  - note taking: joplin
  - e-book viewer: foliate
  - note:
    - descriptive README
    - using justfile for bootstrapring
    - interesting packages to manage multimedia
    - eye protection configuration
    - some interesting packages to manage secrets
- https://gitlab.com/Zaney/zaneyos
  - os: nixos
  - wm: hyprland
  - terminal emulator: kitty
  - launcher: wofi
  - bar: waybar
  - theme: yes
- https://github.com/notusknot/dotfiles-nix/
  - os: nixos
  - wm: hyprland
  - widget: eww
  - terminal emulator: foot
  - launcher: wofi
  - notification: dunst
  - browser: firefox
  - note:
    - each config is modularized
    - minimalist README
- https://github.com/Evertras/nix-systems
  - os: nixos
  - wm: hyprland, dwm, i3
  - terminal emulator: alacritty, kitty, st
  - notification: dunst
  - browser: firefox
  - theme: yes
  - note:
    - has lib to import all sub-directories
    - interesting way to structure dotfiles
- https://github.com/Aylur/dotfiles/tree/main
  - os: nixos
  - wm: hyprland, sway
  - terminal emulator: wezterm
  - browser: firefox
  - theme: yes
    - nice light theme
- https://github.com/hyper-dot/Arch-Hyprland/tree/main
  - os: archlinux
  - wm: hyprland
  - terminal emulator: alacritty
  - notification: dunst
  - bar: waybar
  - note:
    - use multiple files for hyprland config files
- https://github.com/chadcat7/crystal
  - os: nixos
  - wm: hyprland, swayfx
  - terminal emulator: wezterm, kitty, foot
  - widget: ags
  - bar: waybar
  - browser: firefox, brave
  - note taking: obsidian
  - theme: yes
  - note:
    - nice looking widgets
- https://codeberg.org/justgivemeaname/.dotfiles
  - os: nixos
  - wm: gnome
  - terminal emulator: wezterm
  - browser: brave
  - note:
    - good project to learn nix and home-manager
- https://gitlab.com/hmajid2301/dotfiles
  - os: nixos
  - wm: hyprland
  - terminal emulator: wezterm
  - launcher: rofi
  - bar: waybar
- https://gitlab.com/usmcamp0811/dotfiles
- https://gitlab.com/librephoenix/nixos-config
  - os: nixos
  - note:
    - interesting way of using variables in configuration files
