# :snowflake: NixOS dotfiles

- :bento: window manager: [hyprland](https://github.com/hyprwm/Hyprland)
- :milky_way: terminal emulator: [kitty](https://sw.kovidgoyal.net/kitty/)
- :shell: shell: [zsh](https://www.zsh.org/)
- :memo: text editor: [neovim](https://neovim.io/)
- :speech_balloon: notification: [dunst](https://dunst-project.org/)
- :globe_with_meridians: browser: [firefox](https://www.mozilla.org/en-US/firefox/new/)
- :camera: screenshot: [satty](https://github.com/gabm/Satty) + [grim](https://github.com/emersion/grim) + [slurp](https://github.com/emersion/slurp)
- :abc: fonts: [nerd fonts](https://github.com/ryanoasis/nerd-fonts)
- :art: color scheme: [kanagawa](https://github.com/rebelot/kanagawa.nvim)
- :file_folder: file manager: [yazi](https://yazi-rs.github.io/) / [thunar](https://gitlab.xfce.org/xfce/thunar)
- :rocket: application launcher: [rofi](https://github.com/lbonn/rofi)

## Getting started

```bash
# list all available operations
make help
```

```bash
$ # folder description
$ nix-shell -p tree --run 'tree -d -L 1'
.
├── home-manager # Install and configure package at user level.
├── nixos        # Install and configure package at system level.
├── pkgs         # Contains Nix custom packages that are not present in nixpkgs.
├── scripts      # Contains some Nix scripts to be use in home-manager or NixOS configuration files, as well as some shell scripts to use outside of Nix.
└── stow         # Configuration files that need to be writeable are symlinked in this folder.
```

### Fresh NixOS installation

For bootstrapping a fresh NixOS install as root:

```bash
nix-shell -p git just nh
mkdir -p ~/.config && cd ~/.config
git clone https://github.com/l-lin/dotfiles
cd dotfiles
just import-keys
just update-nixos
just update-home
reboot
```

---

## Notes to my future self

:wave: Hello, my future self. Yes, you! Here are some notes for you, as I know
you are forgetful.

### Installation

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

  # By declaring directly their package name.
  # Using this way will only install the package.
  home.packages = with pkgs; [
    your-package
  ];

  # Sometimes, there's an option for that. You can check directly in https://mynixos.com.
  # You can use this syntax if you want to use default options set by home-manager or if
  # some other package needs to know if your package is enabled or not (e.g. stylix).
  programs.your-package = {
    enable = true;
  };
}
```

#### Install Forticlient VPN with SAML

If your company is using Forticlient to connect to their VPN, you won't be able
to use their binary.

Instead, you have to use [openfortivpn](https://github.com/adrienverge/openfortivpn)
with [openfortivpn-webview](https://github.com/gm-vm/openfortivpn-webview) to get
the cookie for authentication.

First download `openfortivpn`.
It should already be present at [vpn/default.nix](./home-manager/modules/vpn/default.nix).

```nix
{ pkgs, ... }: {
  home.packages = with pkgs; [ openfortivpn ];
}
```

Download `openfortivpn-webview` and put the binary in your `$PATH`.
It should already be present by using the derivation [./pkgs/openfortivpn-webview/default.nix]
and importing at [vpn/default.nix](./home-manager/modules/vpn/default.nix).

Then use like this:

```bash

# open VPN in one command line
VPN_HOST=some_host && VPN_PORT=443 \
  && openfortivpn-webview "${VPN_HOST}:${VPN_PORT}" 2>/dev/null \
  | sudo openfortivpn "${VPN_HOST}:${VPN_PORT}" --cookie-on-stdin --pppd-accept-remote
```

> [!NOTE]
> We need to add the `--pppd-accept-remote` since `ppp` v2.5.0.
> See https://github.com/adrienverge/openfortivpn/issues/1076 for more information.

#### Adding external binary to your `$PATH`

If you want to install a tool / binary that is not present in the [`nixpkgs`](https://github.com/NixOS/nixpkgs),
you will need to create a custom package / derivation and import in your home-manager
configuration.

> What are derivations?
>
> Derivations are produced in Nix (the language) by the derivation function (or any
> of the higher-level helpers like mkDerivation or buildPythonPackage). A derivation
> is saved as a .drv file to the nix store. It is ultimately this .drv file, which
> Nix uses to build and install the software or resources (fonts, icon packs, ...).

First create a `pkgs/your-package/default.nix` with the following content:

```nix
{ stdenvNoCC, lib }: stdenvNoCC.mkDerivation {
  # ...
}
```

You can find multiple tutorials online to create your own derivation:

- https://nix.dev/tutorials/packaging-existing-software
- https://zero-to-nix.com/concepts/derivations
- https://ianthehenry.com/posts/how-to-learn-nix/my-first-derivation/
- https://nix.dev/manual/nix/2.22/language/derivations.html
- https://nix4noobs.com/packages/hello_world/

You can use some nice builtins functions:

- [builtins.fetchTarball](https://noogle.dev/f/builtins/fetchTarball)
- [builtins.fetchUrl](https://noogle.dev/f/builtins/fetchurl)
- [builtins.fetchGit](https://noogle.dev/f/builtins/fetchGit)
- [builtins.fetchFromGitHub](https://noogle.dev/f/pkgs/fetchFromGitHub) (:warning: big H)
- [builints.fetchzip](https://noogle.dev/f/pkgs/fetchzip) (:warning: small z)

Do not forget to import your new package in `pkgs/default.nix`:

```nix
pkgs: {
  your-package = pkgs.callPackage ./your-package { };
}
```

Then in your home-manager configuration, you can import like this:

```nix
{ outputs, pkgs, systemSettings, ... }: {
  home.packages = with pkgs; [
    outputs.packages.${systemSettings.system}.openfortivpn-webview
  ];
}
```

Source: https://github.com/Misterio77/nix-starter-configs/issues/62.

You could also use [nix-init](https://github.com/nix-community/nix-init) for generating
Nix packages from URLs with hash prefetching, dependency inference, license detection, ...

#### I want to downgrade/upgrade a package

As you may know (or not, if you forgot), packages are pinned to `nixpkgs`, so you may not
have the latest version of a package, e.g. your favorite `Neovim`.

Or worst, you have a bug or an incompatibility issue with a package pinned by `nixpkgs`.

In Flakes, package versions and hash values are directly tied to the git commit,
of their flake input. To modify the package version, you need to lock the git,
commit of the flake input.

Here's an example of how you can add multiple `nixpkgs` inputs, each using a,
different git commit or branch:

```nix
{
  description = "NixOS/home-manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # ...
  };

  # ...
  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    ...
  } @ inputs:
    # ...
    nixosConfigurations = {
      "${systemSettings.hostname}" = nixpkgs.lib.nixosSystem {
        specialArgs = {
          pkgs-unstable = import nixpkgs-unstable { };
          inherit fileExplorer;
          inherit systemSettings;
          inherit userSettings;
          inherit inputs;
        };
        modules = [./nixos/configuration.nix];
      };
    };
}
```

Then in your package, you can use this pinned `nixpkgs`:

```nix
{ pkgs-unstable, ... }: {
  programs.neovim = {
    enable = true;
    package = pkgs-unstable.neovim;
  };
}
```

Don't forget to apply your change in your home-manager afterwards!

Source: https://nixos-and-flakes.thiscute.world/nixos-with-flakes/downgrade-or-upgrade-packages

#### Some packages are broken after an upgrade

If you are living dangerously, i.e. you are using the unstable version of `nixpkgs`,
each package may be upgraded to their latest version. So you may have some packages
that are not behaving the same as you wanted or are just broken.

Here's a tutorial of someone that used `git bisect` to find and fix his issue:
https://ipetkov.dev/blog/bisecting-nix-configurations/.

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
  # Register custom script as a package so I can call it from anywhere.
  # src: https://discourse.nixos.org/t/link-scripts-to-bin-home-manager/41774/2
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

#### LazyVim configuration

> [!NOTE]
> [LazyVim](https://github.com/LazyVim/LazyVim) is a plugin manager that will download
> the plugins at "runtime". So it does not quite stick to the NixOS philosophy.
> It's recommended to migrate to something else, like configuring directly in
> [home-manager](https://mynixos.com/home-manager/options/programs.neovim), or using
> [NixVim](https://github.com/nix-community/nixvim) instead.

I'm using a symlink to the `${XDG_CONFIG_HOME}/nvim` folder, so LazyVim works
without much issue, i.e. it will download the plugins, but I can't say the same
about plugins that use downloaded binaries, e.g. LSP servers installed by [mason.nvim](https://github.com/williamboman/mason.nvim).

I installed and configured [nix-ld](https://github.com/Mic92/nix-ld), so most binaries
should work without any problem. If not please check below on how to configure it.

I still don't know if I want to migrate NeoVim to be fully Nix compliant or keep
it like this...

#### Theme

I used [stylix](https://github.com/danth/stylix) to manage color schemes and themes.
So it should be easy to add new themes without much hassle.

You can add them at the [themes folder](./home-manager/modules/style/themes/).

#### XDG folder names and home directory as variables

You can access to the XDG folder names and home directory by having `config` as parameter:

```nix
{ config, ... }: {
  somePackage = {
    # Interpolates into ~/some/file.txt
    someOptionThatNeedsHomeDirectory = "${config.home.homeDirectory}/some/file.txt";

    # Interpolates into ~/.config/some/file.txt
    someOptionThatNeedsXdgConfigFolderName = "${config.xdg.configHome}/some/file.txt";

    # Interpolates into ~/.local/share/some/file.txt
    someOptionThatNeedsXdgDataFolderName = "${config.xdg.dataHome}/some/file.txt";

    # Interpolates into ~/.cache/some/file.txt
    someOptionThatNeedsXdgCacheFolderName = "${config.xdg.cacheHome}/some/file.txt";

    # Interpolates into ~/Music/some/file.txt
    # See https://home-manager-options.extranix.com/?query=xdg.userDirs&release=master for the exhaustive list of userDirs.
    someOptionThatNeedsXdgUserDirs = "${config.xdg.userDirs.music}/some/file.txt";
  };
}
```

#### Creating a new secret

You need to put some secret and use it in some configuration?

Check your [secrets private repository](https://github.com/l-lin/secrets).

### Run

#### Adding new zsh completion scripts

Sometimes, some commands are not available in the [default zsh completions](zsh-users/zsh-completions).

However, some tools provide a completion script that is generated for you, e.g.:

```bash
just --completion zsh
helm completion zsh
```

So after adding the completion script in your `${XDG_CONFIG_HOME}/zsh/completions` folder,
you will notice that the completion does not work yet. It's because we are using a plugin
that caches the completion script. So you will need to refresh the cache by calling the
following:

```bash
refresh-zsh-completions
```

Then, open a new terminal session, and you are good to go!

#### Running an external binary on NixOS

> [!NOTE]
> **TLDR:** I installed `nix-ld`, so most binaries should work without any problem.
> If not, check below on how to configure it to make it work for your binary.
>
> Otherwise, there is also `nix-alien` and `steam-run` alternatives.

<details>
<summary>Click me if you really want to know the details...</summary>

HA! Welcome to the dark side of NixOS. You want to run a binary
you downloaded on the internet on NixOS? Nope, you can't!

Well, it's logical as NixOS philosophy is to have reproducible
and immutable environments. So it's logical some programs are not
in the same place as the other Linux distribution.

Precompiled binaries that were not created for NixOS usually have a
so-called link-loader hardcoded into them. On Linux/x86_64 this is for example
`/lib64/ld-linux-x86-64.so.2.` for glibc. NixOS, on the other hand,
usually has its dynamic linker in the glibc package in the Nix store and
therefore cannot run these binaries.

__NixOS is not FHS compliant__

There is something called the [Filesystem Hierarchy Standard](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard)
(FHS) which is a reference describing the conventions used for the layout of
Unix-like systems, e.g. have the essential command binaries under `/bin`, ...

NixOS is **NOT** FHS compliant, and some programs you downloaded on the internet
will try to access hard-coded FHS file path like `/usr/lib` or `/opt`.

Moreover, most programs are using a hard-coded [Executable and Linkable Format (ELF)](https://lwn.net/Articles/631631/)
path to be executed.

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

Here are some methods that worked for me:

##### Patching ELF manually

```bash
# You can manually patch them, and if you're lucky, that's enough:
patchelf --set-interpreter $(patchelf --print-interpreter `which find`) lua-language-server

# You can now execute it like any other binary:
./lua-language-server
```

If that's not enough, e.g. there're some missing libraries:

```bash
$ ldd marksman | grep 'not found'
        libz.so.1 => not found
        libstdc++.so.6 => not found
```

In that case, you need to:

1. find which packages provide those libraries
  - you can use `nix-index` to find the packages
  - or you can use [https://pkgs.org](https://pkgs.org)
  - `libz.so.1` is provided by `zlib` and `libstdc++.so.6` is part of the C/C++ compiler tool chain
1. find the path to those packages in your [Nix store](https://nix4noobs.com/flakes/packages/#nix-store)
  - if the package is not present in your Nix store, you will need to install it

```bash
$ # First generate the database index of all files in our channel (can be quite slow):
$ nix-index
+ querying available packages
+ generating index: 114066 paths found :: 29905 paths not in binary cache :: 00000 paths in queue
+ wrote index of 70,026,341 bytes

$ # We use the power of nix-locate to find the packages which contain the file:
$ nix-locate --minimal --top-level -w lib/libz.so.1
zlib.out
remarkable-toolchain.out
remarkable2-toolchain.out
libz.out
figma-linux.out
$ nix-locate --minimal --top-level -w lib/libstdc++.so.6
robo3t.out
remarkable-toolchain.out
remarkable2-toolchain.out
libgcc.lib

$ # You can find the package using the following command:
$ nix eval 'nixpkgs#zlib.outPath' --raw
/nix/store/lv6nackqis28gg7l2ic43f6nk52hb39g-zlib-1.3.1
$ nix eval 'nixpkgs#stdenv.cc.cc.lib.outPath' --raw
/nix/store/xvzz97yk73hw03v5dhhz3j47ggwf1yq1-gcc-13.2.0-lib
```

Now, patch the [Rpath](https://en.wikipedia.org/wiki/Rpath) of the binary.

```bash
# By patching the RPATH, marksman is now aware of the missing
# libraries and works on NixOS
patchelf \
  --set-rpath "$(nix eval nixpkgs#zlib.outPath --raw)/lib:$(nix eval nixpkgs#stdenv.cc.cc.lib.outPath --raw)/lib" \
  marksman
```

> rpath designates the run-time search path hard-coded in an executable file or
> library. Dynamic linking loaders use the rpath to find required libraries.
>
> Specifically, it encodes a path to shared libraries into the header of an
> executable (or another shared library). This rpath header value (so named in
> the Executable and Linkable Format header standards) may either override or
> supplement the system default dynamic linking search paths.

As you can see, it's quite tedious and error-prone. The following options may be
better.

##### Running using `nix-alien`

[nix-alien](https://github.com/thiagokokada/nix-alien) will help you run unpatched
binaries without modifying them by setting the interpreter and linking the
dynamic libraries needed.

First add `nix-alien` in your home-manager configuration.

It should already be present at [nix-alien](./home-manager/modules/misc/unpatched-binaries/default.nix):

```nix
{ inputs, systemSettings, ... }: {
  home.packages = with inputs.nix-alien.packages.${systemSettings.system}; [ nix-alien ];
}
```

Then, you can run it like this:

```bash
# It will open an interactive form to choose where the 
nix-alien ./marksman
```

It also have other options. I still did not explore them.

##### Using `nix-ld`

[nix-ld](https://github.com/Mic92/nix-ld) provides a shim layer for these binaries.
It is installed in the same location where other Linux distributions install their
link loader, ie. `/lib64/ld-linux-x86-64.so.2` and then loads the actual link loader
as specified in the environment variable `NIX_LD`. In addition, it also accepts a
colon-separated path from library lookup paths in `NIX_LD_LIBRARY_PATH`. This
environment variable is rewritten to `LD_LIBRARY_PATH` before passing execution to
the actual `ld`. This allows you to specify additional libraries that the executable
needs to run.

First add `nix-ld` in your NixOS configuration.

It should already be present at [nix-ld](./nixos/modules/unpatched-binaries.nix):

```nix
{ pkgs, ... }: {
  programs.nix-ld = {
    enable = true;
    package = nix-ld-rs;
    libraries = [
      # ...
    ];
  };
}
```

Now, you will be able to run any binary that only needs to have their interpreter
patched! For example, most LSP servers will be able to run!

If not, use `nix-index` with `nix-locate` to find the package of the missing library:

```bash
$ nix-locate --minimal --top-level -w lib/libgobject-2.0.so.0
remarkable-toolchain.out
remarkable2-toolchain.out
glib.out
```

Then update [unpatched-binaries.nix](./nixos/modules/unpatched-binaries.nix) to include the package,
and apply the change with `make nixos`.

##### Using `steam-run`

`steam-run` is a tool in the Nix package repository that provides an environment
mimicking the traditional FHS, primarily intended for running the Steam gaming
client on NixOS. However, it can be used for other use cases (like this one).

First add `steam-run` in your NixOS configuration (should already be present):

```nix
{ pkgs, ... }: {
  # Run commands in the same FHS environment that is used for Steam: https://store.steampowered.com/
  environment.systemPackages = with pkgs; [ steam-run ];
}
```

```bash
# Once steam-run is installed system-wide, you can run any program in the FHS environment:
steam-run your-program args

# Example running openfortivpn-webclient binary in current folder:
steam-run ./openfortivpn-webclient
```

##### Resources to run binaries in NixOS

- [Packaging/Binaries - NixOS Wiki](https://nixos.wiki/wiki/Packaging/Binaries#Manual_Method)
- [Patching Binaries for NixOS · Rootknecht.net](https://rootknecht.net/blog/patching-binaries-for-nixos/)
- [Frequently Asked Questions — nix.dev documentation](https://nix.dev/guides/faq#how-to-run-non-nix-executables)
- [Running Downloaded Binaries on NixOS](https://nixos-and-flakes.thiscute.world/best-practices/run-downloaded-binaries-on-nixos)
- [Different methods to run a non-nixos executable on Nixos](https://unix.stackexchange.com/questions/522822/different-methods-to-run-a-non-nixos-executable-on-nixos)
- [How programs get run: ELF binaries](https://lwn.net/Articles/631631/)
- [How to make Mason works on NixOS](https://www.reddit.com/r/NixOS/comments/13uc87h/masonnvim_broke_on_nixos/)

Some ways to create a FHS environment:

- https://discourse.nixos.org/t/best-way-to-define-common-fhs-environment/25930
- https://jorel.dev/NixOS4Noobs/fhs.html
- https://nixos-and-flakes.thiscute.world/best-practices/run-downloaded-binaries-on-nixos

</details>

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

- https://search.nixos.org/packages: search Nix packages
- https://search.nixos.org/options: search NixOS options
- https://mynixos.com/search: search NixOS and home-manager options and packages
- https://home-manager-options.extranix.com/: search home-manager options
- https://nixos.wiki/index.php: more in-depth documentation
- https://nix.dev/search.html: more in-depth documentation
- https://nixos.org/manual/nixos/unstable/index.html#ch-configuration: system level configuration documentation
- https://github.com/NixOS/nixpkgs: code source
- https://noogle.dev/: search Nix functions

### References

- [Nix command line reference](https://nix.dev/manual/nix/2.22/command-ref/new-cli/nix)

### Tutorials

- [Best introduction to home-manager for newcomer](https://github.com/Evertras/simple-homemanager)
- [Zero to Nix](https://zero-to-nix.com/)
- [Nix pills](https://nixos.org/guides/nix-pills/)
- [nix.dev](https://nix.dev)
- [Installing NixOS with Hyprland](https://josiahalenbrown.substack.com/p/installing-nixos-with-hyprland)
- [Declarative management of dotfiles with Nix and Home Manager](https://www.bekk.christmas/post/2021/16/dotfiles-with-nix-and-home-manager)
- [Getting started with the Nix ecosystem](https://gist.github.com/thiloho/993be8693571c9868c1661ae0f3c776b)
- [Writing Nix modules](https://nixos.org/manual/nixos/stable/#sec-writing-modules)
- [Nix module system](https://nix.dev/tutorials/module-system/)
- [NixOS and flake unofficial book for beginners](https://nixos-and-flakes.thiscute.world/)
- [Nix cookbook and survival guide](https://nix4noobs.com/)
- [Practical Nix flake anatomy](https://vtimofeenko.com/posts/practical-nix-flake-anatomy-a-guided-tour-of-flake.nix/)

### Interesting topics

- [Smaller stdenv for shells](https://discourse.nixos.org/t/smaller-stdenv-for-shells/28970)

### Inspirations

- https://github.com/Misterio77/nix-starter-configs
- https://github.com/GaetanLepage/nix-config
- https://github.com/ryan4yin/nix-config
- https://gitlab.com/Zaney/zaneyos
- https://github.com/notusknot/dotfiles-nix/
- https://github.com/Evertras/nix-systems
- https://github.com/Aylur/dotfiles
- https://github.com/hyper-dot/Arch-Hyprland
- https://github.com/chadcat7/crystal
- https://codeberg.org/justgivemeaname/.dotfiles
- https://gitlab.com/hmajid2301/dotfiles
- https://gitlab.com/usmcamp0811/dotfiles
- https://gitlab.com/librephoenix/nixos-config
