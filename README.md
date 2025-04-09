# Dotfiles

<summary>:snowflake: NixOS</summary>
<details>

- :bento: window manager: [hyprland](https://github.com/hyprwm/Hyprland)
- :ghost: terminal emulator: [ghostty](https://ghostty.org/)
- :shell: shell: [zsh](https://www.zsh.org/)
- :memo: text editor: [neovim](https://neovim.io/)
- :speech_balloon: notification: [dunst](https://dunst-project.org/)
- :globe_with_meridians: browser: [zen](https://zen-browser.app/)
- :camera: screenshot: [satty](https://github.com/gabm/Satty) + [grim](https://github.com/emersion/grim) + [slurp](https://github.com/emersion/slurp)
- :video_camera: screen recorder: [wf-recorder](https://github.com/ammen99/wf-recorder) + [slurp](https://github.com/emersion/slurp)
- :abc: fonts: [nerd fonts](https://github.com/ryanoasis/nerd-fonts)
- :art: color scheme: [kanagawa](https://github.com/rebelot/kanagawa.nvim)
- :file_folder: file manager: [yazi](https://yazi-rs.github.io/) / [thunar](https://gitlab.xfce.org/xfce/thunar)
- :rocket: application launcher: [rofi](https://github.com/lbonn/rofi)

</details>

<summary>:penguin: Ubuntu</summary>
<details>

- :bento: window manager: [awesomewm](https://awesomewm.org/)
- :ghost: terminal emulator: [ghostty](https://ghostty.org/)
- :shell: shell: [zsh](https://www.zsh.org/)
- :memo: text editor: [neovim](https://neovim.io/)
- :globe_with_meridians: browser: [zen](https://zen-browser.app/)
- :art: color scheme: [kanagawa](https://github.com/rebelot/kanagawa.nvim)
- :file_folder: file manager: [yazi](https://yazi-rs.github.io/) / [thunar](https://gitlab.xfce.org/xfce/thunar)

</details>

<summary>:apple: MacOS</summary>
<details>

- :bento: window manager: [aerospace](https://github.com/nikitabobko/AeroSpace)
- :ghost: terminal emulator: [ghostty](https://ghostty.org/)
- :shell: shell: [zsh](https://www.zsh.org/)
- :memo: text editor: [neovim](https://neovim.io/)
- :globe_with_meridians: browser: [zen](https://zen-browser.app/)
- :art: color scheme: [kanagawa](https://github.com/rebelot/kanagawa.nvim)
- :file_folder: file manager: [yazi](https://yazi-rs.github.io/) / [thunar](https://gitlab.xfce.org/xfce/thunar)

</details>

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

### Fresh installation
#### Installation per distribution

<summary>:snowflake: NixOS</summary>
<details>

```bash
# Clone dotfiles.
nix-shell -p git just
cd ~/.config
git clone https://github.com/l-lin/dotfiles
cd dotfiles

# Install everything.
just import-keys import-secrets
just update-nixos
just update-home
reboot
```

</details>

<summary>:penguin: Ubuntu</summary>
<details>

```bash
# Install curl: https://zero-to-nix.com/start/install.
sudo apt install curl
# Install Nix.
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Clone dotfiles.
nix-shell -p git just
cd ~/.config
git clone https://github.com/l-lin/dotfiles
cd dotfiles

# Install everything.
just import-keys import-secrets
just install-home-standalone
just update-home
reboot
```

</details>

<summary>:apple: MacOS</summary>
<details>

```bash
# Install homebrew: https://brew.sh/.
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Install Nix.
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Clone dotfiles.
nix-shell -p git just
cd ~/.config
git clone https://github.com/l-lin/dotfiles
cd dotfiles

# Install everything.
just import-keys import-secrets
just install-home-standalone
just update-nix-darwin
just update-home
```

</details>

#### Things to do after installation

```bash
# Add navi cheatsheets.
unleash-the-keys
just install-cheatsheets

# Synchronize atuin
atuin login -u l-lin
atuin sync

# Fix dotfiles git remote to use ssh.
wd dotfiles
git remote remove origin && git remote add origin git@github.com:l-lin/dotfiles && git fetch

# Clone your notes.
git clone --recurse-submodules git@github:l-lin/notes "${HOME}/perso/notes"

# Configure Github CLI.
just configure-gh

# Configure jira CLI.
jira init

# Configure colima to work with testcontainers
just configure-colima
```

For macOS:

- Remove keyboard shortcut for dictation (default shortcut is making me popup a notification every now and then).
  - `System settings > Keyboard > Dictation`
- Remove `Ctrl+FX` keyboard shortcuts (otherwise, they won't be usable in nvim).
  - `System settings > Keyboard > Keyboard shortcut > Keyboard: disable all`
- Change screenshot keymap to `cmd-s` and `cmd-shift-s`.
  - `System settings > Keyboard shortcut > Screenshot`
- Install Tridactyl native by executing `:nativeinstall` in your browser.
- Change keyboard layout (may require a reboot).
  - `System settings > Keyboard > Text input > Edit`: Click on `+`, select `Other` and then `us-altgr-intl`
- Add ghostty to control the computer so that `osascript` can send keystrokes for reloading ghostty configuration.
  - `System settings > Privacy & security > Accessibility`: add ghostty
- Remove sound effects.
  - `System settings` > Sound > Sound effects`

---

## Notes to my future self

:wave: Hello, my future self. Yes, you! Here are some notes for you, as I know
you are forgetful.

- [Find a package in the Nixpkgs](https://l-lin.github.io/nix/find-a-package-in-the-Nixpkgs).
- [Install a new package in home-manager](https://l-lin.github.io/nix/home-manager/install-a-new-package-in-home-manager).
- [Install Forticlient VPN with SAML](https://l-lin.github.io/nix/install-Forticlient-VPN-with-SAML-in-NixOS)
- [Add shell script available in `$PATH` in NixOS](https://l-lin.github.io/nix/add-shell-script-available-in-PATH-in-NixOS)
- [Adding external binary to your `$PATH`](https://l-lin.github.io/nix/add-external-binary-in-PATH-in-NixOS)
- [I want to downgrade/upgrade a package](https://l-lin.github.io/nix/downgrade-or-upgrade-a-package-in-NixOS)
- [Use a different version of nixpkgs in home-manager](https://l-lin.github.io/nix/home-manager/use-different-version-of-nixpkgs-in-home-manager)
- [Share variables between modules](https://l-lin.github.io/nix/share-variables-between-Nix-modules)
- [Running an external binary on NixOS](https://l-lin.github.io/nix/running-an-external-binary-on-NixOS)
- [XDG folder names and home directory as variables](https://l-lin.github.io/nix/nix-xdg-folder-names-and-home-directory-as-variables)
- [Pair bluetooth devices](https://l-lin.github.io/unix/pair-bluetooth-devices)

### Some packages are broken after an upgrade

If you are living dangerously, i.e. you are using the unstable version of `nixpkgs`,
each package may be upgraded to their latest version. So you may have some packages
that are not behaving the same as you wanted or are just broken.

Here's a tutorial of someone that used `git bisect` to find and fix his issue:
https://ipetkov.dev/blog/bisecting-nix-configurations/.

### Symlink configuration files whenever you can

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

### LazyVim configuration

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

> [!NOTE]
> I moved all my NeoVim configuration to the `stow/` folder, as updating a NeoVim Lua
> file through home-manager resulted in slow feedback (~20s).

### Styling

I used [stylix](https://github.com/danth/stylix) to manage color schemes and themes.
So it should be easy to add new themes without much hassle.

You can add them at the [themes folder](./home-manager/modules/style/themes/).

### Creating a new secret

You need to put some secret and use it in some configuration?

Check your [secrets private repository](https://github.com/l-lin/secrets).

### Adding new `zsh` completion scripts

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

#### nix-darwin

- [Nix-Darwin dev handbook](https://dev.jmgilman.com/environment/tools/nix/nix-darwin/)
- [Switching to nix-darwin and flakes](https://evantravers.com/articles/2024/02/06/switching-to-nix-darwin-and-flakes/)
- [Package management on macOS with nix-darwin](https://davi.sh/blog/2024/01/nix-darwin/)

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
- https://github.com/ryan4yin/nix-darwin-kickstarter
