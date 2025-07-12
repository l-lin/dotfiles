set quiet
set shell := ["bash", "-c"]

NIXOS_HARDWARE_CONFIGURATION_FILE := './nixos/hardware-configuration.nix'
NIX_PROFILE := 'louis.lin'
NIX_HOST := 'MACM-ML2PCQ1JXG'
THEMES_FOLDER := './home-manager/modules/share/style/themes'

DEFAULT_THEME_DARK := 'kanagawa'
DEFAULT_THEME_LIGHT := 'github-light'

PRE_COMMIT_FILE := './home-manager/modules/vcs/git/.config/git/hooks/scan-nix-files.sh'

# display help
help:
  just --list

# NIXOS --------------------------------------------------------------------------

# generate hardware-configuration
nixos-hardware-config:
  rm "{{NIXOS_HARDWARE_CONFIGURATION_FILE}}"
  nixos-generate-config --show-hardware-config > "{{NIXOS_HARDWARE_CONFIGURATION_FILE}}"

# apply NixOS configuration
update-nixos: nixos-hardware-config
  just info "Applying NixOS configuration..."
  if type nh >/dev/null 2>&1; then \
    nh os switch --hostname "{{NIX_HOST}}" --ask .; \
  else \
    sudo nixos-rebuild switch --flake '.#{{NIX_HOST}}'; \
  fi
  just check-nixos-health

# clean up nixos garbage
clean-nixos:
  just warn "Cleaning up NixOS garbage..."
  sudo nix-collect-garbage -d
  sudo nixos-rebuild boot --flake '.#{{NIX_HOST}}'

# check NixOS configuration
check-nixos-health:
  nix-shell -p nix-health --run nix-health

# find a Nix package
find-nix-package package:
  nix search nixpkgs {{package}}

# find Nix option documentation
find-nix-option option:
  nix-shell -p manix --run "manix '{{option}}'"

#  update Nix flake lock file
update-flake input="all":
  if [[ "{{input}}" == "all" ]]; then \
    just info "Updating Nix flake lock file..." \
    && nix flake update; \
  else \
    just info "Updating Nix flake {{input}}..." \
    && nix flake update {{input}}; \
  fi

# HOME-MANAGER --------------------------------------------------------------------------

# src: https://nix-community.github.io/home-manager/index.xhtml#sec-install-standalone
# install home-manager in standalone
install-home-standalone:
  nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
  nix-channel --update
  nix-shell '<home-manager>' -A install

# apply home-manager configuration
update-home:
  just info "Applying home-manager configuration..."
  if type nh >/dev/null 2>&1; then \
    nh home switch --backup-extension bak --configuration "{{NIX_PROFILE}}" . -- --show-trace; \
  else \
    home-manager switch -b bak --flake '.#{{NIX_PROFILE}}'; \
  fi
  just create-symlinks

# show home-manager news entries
show-home-news:
  home-manager news --flake '.#{{NIX_PROFILE}}'

# clean up home-manager garbage
clean-home:
  just warn "Cleaning up home-manager garbage..."
  nix-collect-garbage -d

# NIX-DARWIN --------------------------------------------------------------------------

# install nix darwin if not already installed
install-nix-darwin:
  if ! type darwin-rebuild >/dev/null 2>&1; then \
    just info "Installing darwin-rebuild" \
    && sudo nix run nix-darwin/master#darwin-rebuild \
      --extra-experimental-features 'nix-command flakes' \
      -- switch --flake '.#{{NIX_HOST}}'; \
  fi

# apply nix-darwin configuration
update-darwin: install-nix-darwin
  just info "Applying nix-darwin configuration"
  sudo darwin-rebuild switch --flake '.#{{NIX_HOST}}'

# add us-altgr-intl keyboard layout to macos
add-keyboard-layout:
  just info "Add us-altgr-intl keyboard layout"
  sudo rm -rf "/Library/Keyboard Layouts/us-altgr-intl.keylayout" \
    && sudo ln -s \
      "${XDG_CONFIG_HOME:-${HOME}/.config}/dotfiles/home-manager/modules/aarch64-darwin/keyboard-layout/us-altgr-intl.keylayout" \
      "/Library/Keyboard Layouts/us-altgr-intl.keylayout"

# STOW --------------------------------------------------------------------------

# add symlinks for files that need to be writeable
create-symlinks: init-directories
  cd stow \
  && for folder in $(find . -type d -maxdepth 1 2>/dev/null); do \
    if [[ "${folder}" != '.' ]] && [[ "${folder}" != './.git' ]]; then \
      app=$(echo "${folder}" | sed 's~./~~') \
      && just info "Add symlinks for ${app}" \
      && stow --delete -t "${HOME}" "${app}" \
      && stow -t "${HOME}" "${app}"; \
    fi; \
  done

# remove-symlinks
remove-symlinks folder:
  cd stow && stow --delete -t "${HOME}" "{{folder}}"

[private]
init-directories:
  cd stow \
  && find . -mindepth 2 -type d | sed 's|^\./||' | grep '/' | while read folder; do \
    mkdir -p "${HOME}/${folder}"; \
  done

# INSTALLATION / CONFIGURATION --------------------------------------------------------------------------

# import SSH keys, SOPS age key and create git allowed signers
import-keys:
  nix-shell --command zsh -p bitwarden-cli jq ssh-to-age --run "./scripts/import-keys.sh {{NIX_PROFILE}}"

# import secrets repository
import-secrets:
  ./scripts/import-secrets.sh {{NIX_PROFILE}}

# install navi cheatsheets if not present
install-cheatsheets:
  cheats=('github.com/l-lin/cheats' 'github.com/l-lin/work-cheats') \
    && for c in ${cheats[@]}; do \
      host=$(echo ${c} | awk -F'/' '{print $1}') \
      && owner=$(echo ${c} | awk -F'/' '{print $2}') \
      && repo=$(echo ${c} | awk -F'/' '{print $3}') \
      && just install-cheatsheet ${host} ${owner} ${repo}; \
    done

[private]
install-cheatsheet host owner repo:
  cheatsheet_name="{{owner}}__{{repo}}" \
    && folder_name="$(echo $(navi info cheats-path)/${cheatsheet_name})" \
    && if [ -d ${folder_name} ]; then \
      just info "Cheatsheet '${cheatsheet_name}' already exists, skipping..."; \
    else \
      just info "Installing cheatsheet '${cheatsheet_name}'."; \
      git clone "git@{{host}}:{{owner}}/{{repo}}" "${folder_name}"; \
    fi

# configure Github CLI
configure-gh:
  just info "Authenticating with Github CLI"
  gh auth login
  just info "Add Copilot extension"
  gh extension install github/gh-copilot

# src: https://golang.testcontainers.org/system_requirements/using_colima/
# configure colima to work with testcontainers
configure-colima:
  just info "Creating symbolink link from Docker socket"
  sudo ln -sf $HOME/.colima/default/docker.sock /var/run/docker.sock
  just info "Restarting colima"
  colima stop
  colima start --network-address

# THEME --------------------------------------------------------------------------

# change theme
change-theme to:
  if [[ ! -d "{{THEMES_FOLDER}}/{{to}}" ]]; then \
    supported_themes=$(find {{THEMES_FOLDER}} -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | tr '\n' ' ') \
    && just error "Unsupported theme '{{to}}', expecting one of '${supported_themes% }'!" >/dev/stderr && exit 1; \
  fi
  just info "Changing theme to '{{to}}'..."
  sed -i '' 's~theme = "\(.*\)"~theme = "{{to}}"~' flake.nix
  just update-home
  just reload-apps

# switch polarity from dark to light or vice versa
switch-polarity:
  current_theme=$(just get-current-theme) && \
  if [[ "{{DEFAULT_THEME_LIGHT}}" == "${current_theme}" ]]; then \
    just change-theme '{{DEFAULT_THEME_DARK}}' \
    && just change-macos-polarity true; \
  else \
    just change-theme '{{DEFAULT_THEME_LIGHT}}' \
    && just change-macos-polarity false; \
  fi

[private]
get-current-theme:
  grep 'theme = ' flake.nix | sed 's~theme = "\(.*\)"; #.*~\1~' | sed 's/ //g'

[private]
reload-pyprland:
  just info "Reloading pyprland configuration..."
  pypr reload

[private]
reload-apps:
  just info "Reloading tmux"
  tmux source "${XDG_CONFIG_HOME}/tmux/tmux.conf"
  if type awesome-client >/dev/null 2>&1; then \
    just reload-awesome; \
  fi

[private]
reload-awesome:
  just info "Reloading awesome"
  echo 'awesome.restart()' | awesome-client 2>/dev/null || true
  just info "Reloading Slack"
  pgrep -x slack > /dev/null && (pkill slack && slack >/dev/null 2>&1&) || true
  just info "Reloading obsidian"
  pgrep electron > /dev/null && (pkill electron && obsidian >/dev/null 2>&1&) || true

# Switch polarity in macOS by calling osascript.
# src:
# - https://norday.tech/posts/2020/switch-dark-mode-os/
# - https://apple.stackexchange.com/a/443362 for changing wallpaper
[private]
change-macos-polarity is_dark:
  if type osascript >/dev/null 2>&1; then \
    just info "Changing macOS polarity" \
    && osascript -l JavaScript -e "Application('System Events').appearancePreferences.darkMode = {{is_dark}}" > /dev/null \
    && osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"${HOME}/Pictures/wallpaper.jpg\" as POSIX file" \
    && osascript -e 'tell application "System Events" to keystroke "," using {command down, shift down}'; \
  fi

# ------------------------------------------------------------------------

# NOTE: When using user.js, it's not possible to use firefox sync, so I need to install them manually.
# open firefox add-ons to install
open-firefox-add-ons:
  add_ons=('bitwarden-password-manager' 'darkreader' 'human-factory' 'languagetool' 'multi-account-containers' 'ninja-cookie' 'refined-doctolib' 'tridactyl-vim' 'ublock-origin') \
  && for add_on in ${add_ons[@]}; do \
    xdg-open "https://addons.mozilla.org/en-US/firefox/addon/${add_on}/"; \
  done

# LOGGING ------------------------------------------------------------------------

BLUE := '\033[1;30;44m'
YELLOW := '\033[1;30;43m'
RED := '\033[1;30;41m'
NC := '\033[0m'

[private]
info msg:
  echo -e "{{BLUE}} I {{NC}} {{msg}}"

[private]
warn msg:
  echo -e "{{YELLOW}} W {{NC}} {{msg}}"

[private]
error msg:
  echo -e "{{RED}} E {{NC}} {{msg}}"
