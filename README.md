# :snowflake: NixOS dotfiles

## Info

- :bento: window manager: [hyprland](https://github.com/hyprwm/Hyprland)
- :milky_way: terminal emulator: [alacritty](https://alacritty.org/)
- :shell: shell: [zsh](https://www.zsh.org/)
- :memo: text editor: [neovim](https://neovim.io/)
- :speech_balloon: notification: [dunst](https://dunst-project.org/)
- :globe_with_meridians: browser: [firefox](https://www.mozilla.org/en-US/firefox/new/)
- :camera: screenshot: [satty](https://github.com/gabm/Satty) + [grim](https://github.com/emersion/grim) + [slurp](https://github.com/emersion/slurp)
- :abc: fonts: [nerd fonts](https://github.com/ryanoasis/nerd-fonts)
- :art: color scheme: [kanagawa](https://github.com/rebelot/kanagawa.nvim)
- :file_folder: file manager: [lf](https://github.com/gokcehan/lf) / [thunar](https://gitlab.xfce.org/xfce/thunar)
- :rocket: application launcher: [wofi](https://hg.sr.ht/~scoopta/wofi)

## Getting started

```bash
# list all available operations
make help
```

```bash
# Install and configure package at user level.
home-manager/
# Install and configure package at system level.
nixos/
# Configuration files that need to be writeable are symlinked in this folder.
stow/
```

## Notes to my future self

:wave: Hello, my future self. Yes, you! Here are some notes for you, as I know
you are forgetful.

### Installation

#### Fresh NixOS installation

For bootstrapping a fresh NixOS install as root:

```bash
nix-shell -p git gnumake
git clone https://github.com/l-lin/dotfiles
cd dotfiles
make nixos
make home
reboot

# synchronize shell history
atuin login -u l-lin
```

#### Find a package in the Nixpkgs

You can find the package directly in [NixOS search engine](https://search.nixos.org)
or using command line:

```bash
nix search nixpkgs your_package
```

[MyNixOS](https://mynixos.com) is a nice website that contains all the options
needed to configure your NixOS / home-manager / package.

Another website that list all the home-manager options:
[Home manager option search](https://home-manager-options.extranix.com/).

#### Install a new package in home-manager

Once you have the package name, you can install it in the `home-manager/` folder.

There are several ways to install a new package in home-manager:

```nix
{ pkgs, ... }: {

  # By declaring directly their package name
  home.packages = with pkgs; [
    your-package
  ];

  # Sometimes, there's an option for that. You can check directly in https://mynixos.com.
  # You will this syntax if you need to configure your package the "Nix way".
  programs.your-package = {
    enable = true;
  };
}
```

### Configuration

#### Symlink configuration files whenever you can

There's a "Nix way" of configuring package. It is like a good abstraction, but
you **will prefer** to have your configuration in the original format and create
symlinks on them.

There are several advantages of doing like this:

- you can refer to the package documentation to make your modification
- you can use linter/treesitter/lsp/whatever on the configuration file
- in case you change your OS (once again), you will still be able to re-use your dotfiles

However, you will not be able to use Nix variables. So if the package does not
need to have any Nix variable, you can configure your package like this:

```nix
# Create symlink on the whole config/ folder on `~/.config/nvim`.
xdg.configFile.nvim = {
  source = ./config;
  recursive = true;
};

# Create a symlink on a single file at `~`.
home.file.".gitconfig".source = ./config/.gitconfig;

# If you need to use some Nix option along with the configuration file, you
# can use the Nix builtin function `builtins.readFile`
programs.tmux = {
  enable = true;
  shell = "${pkgs.zsh}/bin/zsh";
  extraConfig = ''
    ${builtins.readFile ./.tmux.conf}
  '';
};

# If you need to write text directly in the nix file, because you need to use
# some nix variable:
xdg.configFile."waybar/colorscheme.css".text = ''
@define-color fg #${palette.base05};
@define-color fg-alt #${palette.base00};
@define-color bg #${palette.base00};
@define-color bg-alt #${palette.base0D};
'';
```

I know you will think there's no consistency, sometimes I'm using Nix to configure
applications, sometimes, I use symlink... I wonder if I should just use Nix / home-manager
to handle all the package installation stuff and symlink the configuration files...
Only time will tell.

#### Write a shell script that will be available in PATH

If you need to have a shell script available from anywhere,
you will need to create like this:

```nix
home.packages = with pkgs; [
  (writeShellScriptBin "my-awesome-script" ''
    ${builtins.readFile ./my-awesome-script}
  '')
];
```

See https://discourse.nixos.org/t/link-scripts-to-bin-home-manager/41774/2.

---

## Resources

There are lots of Nix documentation, but it's quite hard to find the "right"
one depending on your level of understanding of Nix.
The official Nix documentation delves a bit too much on the concepts (for the
right reasons), whereas I just want to make something work fast.

I found [Evertras introduction to home-manager](https://github.com/Evertras/simple-homemanager)
is the best documentation to start with Nix, along with [zero-to-nix](https://zero-to-nix.com/).

### Where to search?

Most of the documentation you will search are the following:

- https://mynixos.com/search
  - search NixOS and home-manager options and packages
- https://search.nixos.org/packages
  - search NixOS and home-manager packages
- https://home-manager-options.extranix.com/
  - search home-manager options
- https://nixos.wiki/index.php
  - more in-depth documentation
- https://nix.dev/search.html
  - more in-depth documentation

### References

- [Nix command line reference](https://nix.dev/manual/nix/2.22/command-ref/new-cli/nix)

### Tutorials

- [Best introduction to home-manager for newcomer](https://github.com/Evertras/simple-homemanager)
- [Zero to Nix](https://zero-to-nix.com/)
- [nix.dev](https://nix.dev)
- [Installing NixOS with Hyprland](https://josiahalenbrown.substack.com/p/installing-nixos-with-hyprland)
- [Declarative management of dotfiles with Nix and Home Manager](https://www.bekk.christmas/post/2021/16/dotfiles-with-nix-and-home-manager)
- [Getting started with the Nix ecosystem](https://gist.github.com/thiloho/993be8693571c9868c1661ae0f3c776b)
- [Writing Nix modules](https://nixos.org/manual/nixos/stable/#sec-writing-modules)
- [Nix module system](https://nix.dev/tutorials/module-system/)
- [NixOS and flake unofficial book for beginners](https://nixos-and-flakes.thiscute.world/)

