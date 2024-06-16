# :snowflake: NixOS dotfiles

## Info

- :bento: window manager: [hyprland](https://github.com/hyprwm/Hyprland)
- :milky_way: terminal emulator: [kitty](hhttps://sw.kovidgoyal.net/kitty/)
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

#### Share variables between modules

It's possible to share variables between modules, and it's quite useful if you
want to set some values depending on which Nix file you import (e.g. for theming
purpose). This promote modular and reusable configurations in NixOS and home-manager.

First define the variable in the module A using `mkOption`:

```nix
{ config, lib, pkgs, ... }:

with lib;

let
  myVariable = "Hello, World!";
in
{
  options.myModuleA.myVariable = mkOption {
    # You can find the exhaustive list of types here: https://nlewo.github.io/nixos-manual-sphinx/development/option-types.xml.html
    type = types.str;
    default = myVariable;
    description = "A variable defined in module A";
  };

  config = {
    myModuleA.myVariable = myVariable;

    # Every options MUST now be inside `config`.
    gtk.enable = true;
  };
}
```

Access the variable in another module:

```nix
{ config, lib, pkgs, ... }:

let
  myVariableFromA = config.myModuleA.myVariable;
in
{
  options.myModuleB.someOption = mkOption {
    type = types.str;
    default = myVariableFromA;
    description = "An option in module B using a variable from module A";
  };

  config = {
    myModuleB.someOption = myVariableFromA;
  };
}
```

Finally, import both modules:

```nix
{ config, pkgs, ... }:

{
  imports = [
    ./moduleA.nix
    ./moduleB.nix
  ];
}
```

See https://nixos.wiki/wiki/NixOS:config_argument.

#### Pair bluetooth devices

```bash
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

> [!TIP]
> Some keyboards sends a pass code which has to be typed in on the
> **bluetooth keyboard** followed by the key "Enter" in order to pair successfully:
>
> ```log
> [bluetooth]# pair YY:YY:YY:YY:YY:YY
> [CHG] Device YY:YY:YY:YY:YY:YY Connected: no
> [CHG] Device YY:YY:YY:YY:YY:YY Connected: yes
> [agent] Passkey: 103760
> ```

### Run

#### Running a binary

HA! Welcome to the dark side of NixOS. You want to run a binary
you downloaded on the internet on NixOS? Nope, you can't!

Well, it's logical as NixOS philosophy is to have reproducible
and immutable environments. So it's logical some programs are not
in the same place as the other Linux distribution.

__NixOS is not FHS compliant__

There is something called the [Filesystem Hierarchy Standard](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard)
(FHS) which is a reference describing the conventions used for the layout of
Unix-like systems, e.g. have the essential command binaries under `/bin`, ...

NixOS is **NOT** FHS compliant, and some programs you downloaded on the internet
will try to access hard-coded FHS file path like `/usr/lib` or `/opt`.

Moreover, most programs are using a hard-coded [Executable and Linkable Format (ELF)](https://lwn.net/Articles/631631/)
path to be executed.

> [!NOTE]
> This format is a common standard file format for executable
> files, object code, shared libraries, and core dumps.
>
> Generally, we write most programs in high-level languages such as C or C++.
> These programs cannot be directly executed on the CPU because the CPU doesn't
> understand these instructions. Instead, we use a compiler that compiles the
> high-level language into object code. Using a linker, we also link the object
> code with shared libraries to get a binary file.
>
> As a result, the binary file has instructions that the CPU can understand and
> execute. The binary file can adopt any format that defines the structure it
> should follow. However, the most common of these structures is the ELF format.

So you may encounter some error like this:

```log
[ERROR][2024-06-13 14:07:39] .../vim/lsp/rpc.lua:734	"rpc"	"/home/l-lin/.local/share/nvim/mason/bin/lua-language-server"	"stderr"	"Could not start dynamically linked executable: /home/l-lin/.local/share/nvim/mason/packages/lua-language-server/libexec/bin/lua-language-server\nNixOS cannot run dynamically linked executables intended for generic\nlinux environments out of the box. For more information, see:\nhttps://nix.dev/permalink/stub-ld\n"
```

So what can you do?

As it turns out, there are [10 different methods to run a non-nixos executable on Nixos](https://unix.stackexchange.com/questions/522822/different-methods-to-run-a-non-nixos-executable-on-nixos)! :scream:

For now, I manually patch them, and if I'm lucky, that's enough:

```bash
patchelf --set-interpreter $(patchelf --print-interpreter `which find`) lua-language-server
```

If that's not enough... Well I still don't know as I still dread going down the
rabbit hole...

Some resources:

- [Packaging/Binaries - NixOS Wiki](https://nixos.wiki/wiki/Packaging/Binaries#Manual_Method)
- [Patching Binaries for NixOS · Rootknecht.net](https://rootknecht.net/blog/patching-binaries-for-nixos/)
- [Frequently Asked Questions — nix.dev documentation](https://nix.dev/guides/faq#how-to-run-non-nix-executables)
- [Running Downloaded Binaries on NixOS](https://nixos-and-flakes.thiscute.world/best-practices/run-downloaded-binaries-on-nixos)
- [Different methods to run a non-nixos executable on Nixos](https://unix.stackexchange.com/questions/522822/different-methods-to-run-a-non-nixos-executable-on-nixos)
- [How programs get run: ELF binaries](https://lwn.net/Articles/631631/)

Some ways to create a FHS environment:

- https://discourse.nixos.org/t/best-way-to-define-common-fhs-environment/25930
- https://jorel.dev/NixOS4Noobs/fhs.html
- https://nixos-and-flakes.thiscute.world/best-practices/run-downloaded-binaries-on-nixos


### Misc

#### Why the hell am I doing this?

Yes, I know, it's sometimes painful to use NixOS... You are not alone:

- https://discourse.nixos.org/t/how-to-make-learning-programming-on-nix-less-painful/34729/4
- https://www.reddit.com/r/NixOS/comments/wqlcsd/what_are_the_biggest_pain_points_with_nix_and/
- http://www.willghatch.net/blog/2020/06/27/nixos-the-good-the-bad-and-the-ugly/
- ...

Just remember you are learning something, especially better understanding of the
Linux system structure.

Take walk, breath, do something else, and come back. Don't go down a rabbit hole
before asking yourself if that's really what you want.

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

